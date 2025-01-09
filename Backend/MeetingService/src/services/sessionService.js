const { openvidu, verifyOpenViduConnection } = require('../config/openvidu');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');

class SessionService {
    constructor() {
        this.recordingRetries = new Map();
        this.connections = new Map(); // Track connections per session
    }

    async createSession(sessionId) {
        try {
            // Verify connection before attempting to create session
            const isConnected = await verifyOpenViduConnection();
            if (!isConnected) {
                throw new AppError(503, 'OpenVidu server is not accessible');
            }

            const existingSession = await this.getActiveSession(sessionId);
            if (existingSession) {
                throw new AppError(409, 'Session ID already exists');
            }

            const sessionProperties = {
                customSessionId: sessionId,
                recordingMode: 'MANUAL',
                defaultRecordingProperties: {
                    hasAudio: true,
                    hasVideo: true
                }
            };

            const session = await openvidu.createSession(sessionProperties);
            logger.info(`Session created with ID: ${session.sessionId}`);
            return session;
        } catch (error) {
            logger.error('Error creating session:', {
                sessionId,
                error: error.message,
                stack: error.stack
            });

            if (error instanceof AppError) {
                throw error;
            }

            if (error.message.includes('404')) {
                throw new AppError(503, 'OpenVidu server is not accessible');
            }

            throw new AppError(500, `Failed to create session: ${error.message}`);
        }
    }

    async generateToken(session, role = 'PUBLISHER') {
        try {
            // Create a connection first
            const connection = await this.createConnection(session.sessionId, { role });
            return connection.token;
        } catch (error) {
            logger.error('Error generating token:', error);
            throw new AppError(500, 'Failed to generate token');
        }
    }

    async getActiveSession(sessionId) {
        try {
            const sessions = await openvidu.activeSessions;
            return sessions.find(s => s.sessionId === sessionId);
        } catch (error) {
            logger.error('Error getting active session:', error);
            throw new AppError(500, 'Failed to get active session');
        }
    }

    async closeSession(sessionId) {
        try {
            const session = await this.getActiveSession(sessionId);
            if (session) {
                await session.close();
                logger.info(`Session closed: ${sessionId}`);
                return true;
            }
            return false;
        } catch (error) {
            logger.error('Error closing session:', error);
            throw new AppError(500, 'Failed to close session');
        }
    }

    async getActiveSessions() {
        try {
            const sessions = await openvidu.activeSessions;
            return sessions.map(session => ({
                sessionId: session.sessionId,
                createdAt: session.createdAt,
                connections: session.activeConnections.length
            }));
        } catch (error) {
            logger.error('Error getting active sessions:', error);
            throw new AppError(500, 'Failed to get active sessions');
        }
    }

    async getSessionInfo(sessionId) {
        try {
            const session = await this.getActiveSession(sessionId);
            if (!session) {
                throw new AppError(404, 'Session not found');
            }
            return {
                sessionId: session.sessionId,
                createdAt: session.createdAt,
                connections: session.activeConnections.length,
                recording: session.recording,
                // Add other relevant session info
            };
        } catch (error) {
            logger.error('Error getting session info:', error);
            throw new AppError(500, 'Failed to get session info');
        }
    }

    async startRecording(sessionId, recordingOptions = {}) {
        try {
            const session = await this.getActiveSession(sessionId);
            if (!session) {
                throw new AppError(404, 'Session not found');
            }

            // Check active connections
            const activeConnections = this.connections.get(sessionId)?.size || 0;
            if (activeConnections === 0) {
                throw new AppError(406, 'Session has no connected participants');
            }

            // Create recording properties according to OpenVidu RecordingProperties interface
            const properties = {
                name: recordingOptions.name || `${sessionId}-${Date.now()}`,
                hasAudio: recordingOptions.hasAudio ?? true,
                hasVideo: recordingOptions.hasVideo ?? false,
                outputMode: recordingOptions.outputMode || "COMPOSED",
                recordingLayout: recordingOptions.recordingLayout || "BEST_FIT",
                resolution: "1280x720",
                frameRate: 25,
                shmSize: 536870912
            };

            const recording = await openvidu.startRecording(sessionId, properties);
            logger.info(`Recording started for session ${sessionId}:`, {
                recordingId: recording.id,
                sessionId: recording.sessionId,
                name: recording.name
            });

            return recording;
        } catch (error) {
            logger.error('Error starting recording:', {
                error: error.message,
                sessionId,
                stack: error.stack
            });
            
            if (error.message?.includes('501')) {
                throw new AppError(501, 'OpenVidu recording module is disabled. Please enable OPENVIDU_RECORDING=true');
            }
            if (error.message?.includes('404')) {
                throw new AppError(404, 'Session not found');
            }
            if (error.message?.includes('406')) {
                throw new AppError(406, 'Session has no connected participants');
            }
            if (error.message?.includes('409')) {
                throw new AppError(409, 'Session is already being recorded');
            }
            throw new AppError(500, `Failed to start recording: ${error.message}`);
        }
    }

    async handleParticipantLeave(sessionId) {
        try {
            const session = await this.getActiveSession(sessionId);
            const retryInfo = this.recordingRetries.get(sessionId);
            
            if (!session || !retryInfo) return;

            // If all participants have left
            if (session.activeConnections.length === 0) {
                // Stop current recording segment
                await this.stopRecording(retryInfo.currentRecording);
                logger.info(`All participants left session ${sessionId}, pausing recording`);

                // Clear any existing timeout
                if (retryInfo.retryTimeout) {
                    clearTimeout(retryInfo.retryTimeout);
                }

                // Set up retry timeout (5 minutes)
                retryInfo.retryTimeout = setTimeout(async () => {
                    try {
                        const currentSession = await this.getActiveSession(sessionId);
                        
                        if (!currentSession || currentSession.activeConnections.length === 0) {
                            logger.info(`No participants rejoined session ${sessionId} after 5 minutes, ending recording`);
                            this.recordingRetries.delete(sessionId);
                            // Trigger meeting end if needed
                            // await this.endMeeting(sessionId);
                        }
                    } catch (error) {
                        logger.error('Error handling recording retry timeout:', error);
                    }
                }, 5 * 60 * 1000); // 5 minutes

                // Set up participant rejoin monitoring
                session.on('streamCreated', async () => {
                    const currentSession = await this.getActiveSession(sessionId);
                    if (currentSession?.activeConnections.length > 0) {
                        // Clear retry timeout
                        clearTimeout(retryInfo.retryTimeout);
                        
                        // Start new recording segment
                        const newRecording = await this.startRecording(sessionId, retryInfo.properties);
                        retryInfo.currentRecording = newRecording.id;
                        retryInfo.segments.push({
                            id: newRecording.id,
                            startTime: Date.now()
                        });
                        
                        logger.info(`Participants rejoined session ${sessionId}, resuming recording`);
                    }
                });
            }
        } catch (error) {
            logger.error('Error handling participant leave:', error);
        }
    }

    async getRecordingInfo(sessionId) {
        const retryInfo = this.recordingRetries.get(sessionId);
        if (!retryInfo) {
            return null;
        }

        return {
            sessionId,
            currentRecordingId: retryInfo.currentRecording,
            startTime: new Date(retryInfo.startTime),
            segments: retryInfo.segments.map(seg => ({
                id: seg.id,
                startTime: new Date(seg.startTime)
            })),
            totalDuration: Math.floor((Date.now() - retryInfo.startTime) / 1000) // in seconds
        };
    }

    async stopRecording(recordingId) {
        try {
            const recording = await openvidu.stopRecording(recordingId);
            logger.info(`Recording stopped: ${recordingId}`);
            return recording;
        } catch (error) {
            logger.error('Error stopping recording:', error);
            if (error.message?.includes('404')) {
                throw new AppError(404, 'Recording not found');
            }
            if (error.message?.includes('406')) {
                throw new AppError(406, 'Recording has not started yet');
            }
            throw new AppError(500, 'Failed to stop recording');
        }
    }

    async getRecording(recordingId) {
        try {
            const recording = await openvidu.getRecording(recordingId);
            return recording;
        } catch (error) {
            logger.error('Error getting recording:', error);
            if (error.message?.includes('404')) {
                throw new AppError(404, 'Recording not found');
            }
            throw new AppError(500, 'Failed to get recording');
        }
    }

    async getAllRecordings() {
        try {
            const recordings = await openvidu.listRecordings();
            return recordings;
        } catch (error) {
            logger.error('Error listing recordings:', error);
            throw new AppError(500, 'Failed to list recordings');
        }
    }

    async createConnection(sessionId, connectionOptions = {}) {
        try {
            const session = await this.getActiveSession(sessionId);
            if (!session) {
                throw new AppError(404, 'Session not found');
            }

            // Create connection with OpenVidu server
            const connection = await session.createConnection({
                type: 'WEBRTC',
                role: connectionOptions.role || 'PUBLISHER',
                data: connectionOptions.data || '',
                record: true,
                kurentoOptions: {
                    videoMaxRecvBandwidth: 1000,
                    videoMinRecvBandwidth: 300,
                    videoMaxSendBandwidth: 1000,
                    videoMinSendBandwidth: 300,
                    allowedFilters: []
                }
            });

            // Track the connection
            if (!this.connections.has(sessionId)) {
                this.connections.set(sessionId, new Set());
            }
            this.connections.get(sessionId).add(connection.connectionId);

            return connection;
        } catch (error) {
            logger.error('Error creating connection:', error);
            throw new AppError(500, `Failed to create connection: ${error.message}`);
        }
    }

    // Add method to handle connection events
    async handleConnectionCreated(sessionId, connectionId) {
        if (!this.connections.has(sessionId)) {
            this.connections.set(sessionId, new Set());
        }
        this.connections.get(sessionId).add(connectionId);
        logger.info(`Connection ${connectionId} created in session ${sessionId}`);
    }

    async handleConnectionDestroyed(sessionId, connectionId) {
        if (this.connections.has(sessionId)) {
            this.connections.get(sessionId).delete(connectionId);
            logger.info(`Connection ${connectionId} destroyed in session ${sessionId}`);
        }
    }
}

module.exports = new SessionService(); 
