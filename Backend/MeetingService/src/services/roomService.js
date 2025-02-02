const { roomService, AccessToken, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_URL } = require('../config/livekit');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');
const { EgressClient } = require('livekit-server-sdk');

class RoomService {
    async createRoom(roomName, metadata = {}) {
        try {
            const existingRoom = await this.getActiveRoom(roomName);
            if (existingRoom) {
                throw new AppError(409, 'Room name already exists');
            }

            const room = await roomService.createRoom({
                name: roomName,
                emptyTimeout: 600, // 10 minutes
                maxParticipants: 20,
                metadata: JSON.stringify(metadata)
            });

            logger.info(`Room created: ${roomName}`);
            return room;
        } catch (error) {
            logger.error('Error creating room:', error);
            throw new AppError(500, 'Failed to create room');
        }
    }

    async getActiveRoom(roomName) {
        try {
            const rooms = await roomService.listRooms();
            return rooms.find(r => r.name === roomName);
        } catch (error) {
            logger.error('Error getting active room:', error);
            throw new AppError(500, 'Failed to get active room');
        }
    }

    async getRoomInfo(roomName) {
        try {
            const room = await this.getActiveRoom(roomName);
            if (!room) {
                throw new AppError(404, 'Room not found');
            }

            return {
                sid: room.sid,
                name: room.name,
                numParticipants: room.numParticipants,
                creationTime: room.creationTime,
                activeRecording: room.activeRecording,
                metadata: room.metadata ? JSON.parse(room.metadata) : {}
            };
        } catch (error) {
            // actually this means that the room is not found
            if (error.message.includes('Room not found')) {
                throw new AppError(404, 'Room not found');
            }

            logger.error('Error getting room info:', error);
            throw new AppError(500, 'Failed to get room info');
        }
    }

    async deleteRoom(roomName) {
        try {
            const room = await this.getActiveRoom(roomName);
            if (!room) {
                return false;
            }

            // Stop any active recording before deleting
            try {
                await this.stopRecording(roomName);
            } catch (error) {
                logger.warn('Failed to stop recording before room deletion:', error);
            }

            await roomService.deleteRoom(roomName);
            logger.info(`Room deleted: ${roomName}`);
            return true;
        } catch (error) {
            logger.error('Error deleting room:', error);
            throw new AppError(500, 'Failed to delete room');
        }
    }

    async startRecording(roomName, options = {}) {
        try {
            logger.info(`Starting recording for room: ${roomName}`);
            
            const room = await this.getActiveRoom(roomName);
            if (!room) {
                throw new AppError(404, 'Room not found');
            }

            const egressClient = new EgressClient(
                LIVEKIT_URL,
                LIVEKIT_API_KEY,
                LIVEKIT_API_SECRET
            );

            // Check for existing recording
            const activeEgresses = await egressClient.listEgress({ 
                roomName,
                active: true
            });

            if (activeEgresses?.length > 0) {
                const existing = activeEgresses[0];
                return {
                    recordingId: existing.egressId,
                    status: this.getEgressRecordingStatus(existing.status),
                    roomName,
                    startedAt: new Date(Number(existing.startedAt) / 1000000).toISOString()
                };
            }

            // AWS S3 Configuration
            const s3Config = {
                accessKey: process.env.AWS_ACCESS_KEY,
                secret: process.env.AWS_SECRET_KEY ,
                bucket: process.env.AWS_BUCKET_NAME || 'agilemeets-meetings',
                region: 'eu-central-1',
                endpoint: 's3.eu-central-1.amazonaws.com'
            };

            const timestamp = new Date().toISOString();
            const filename = `recordings/${roomName}/${timestamp}/recording.ogg`;

            const output = {
                file: {
                    filepath: filename,
                    s3: {
                        accessKey: s3Config.accessKey,
                        secret: s3Config.secret,
                        bucket: s3Config.bucket,
                        region: s3Config.region,
                        endpoint: s3Config.endpoint,
                        forcePathStyle: false
                    }
                }
            };

            const recording = await egressClient.startRoomCompositeEgress(
                roomName,
                output,
                {
                    audioOnly: true,
                    encodingOptions: {
                        audioBitrate: 128,
                        audioFrequency: 48000,
                        audioChannels: 1
                    }
                }
            );

            return {
                recordingId: recording.egressId,
                status: this.getEgressRecordingStatus(recording.status),
                roomName,
                startedAt: new Date(Number(recording.startedAt) / 1000000).toISOString(),
                audioUrl: `https://${process.env.AWS_BUCKET_NAME || 'agilemeets-meetings'}.s3.eu-central-1.amazonaws.com/${recording.file.filename}`
            };
        } catch (error) {
            logger.error('Error starting recording:', error);
            throw new AppError(500, 'Failed to start recording');
        }
    }

    async stopRecording(roomName) {
        try {
            const egressClient = new EgressClient(
                LIVEKIT_URL,
                LIVEKIT_API_KEY,
                LIVEKIT_API_SECRET
            );

            const egresses = await egressClient.listEgress({ 
                roomName,
                active: true
            });

            if (!egresses?.length) {
                return;
            }

            await egressClient.stopEgress(egresses[0].egressId);
            logger.info(`Recording stopped for room: ${roomName}`);
        } catch (error) {
            logger.error('Error stopping recording:', error);
            throw new AppError(500, 'Failed to stop recording');
        }
    }

    async getRecordings(roomName) {
        try {
            const egressClient = new EgressClient(
                LIVEKIT_URL,
                LIVEKIT_API_KEY,
                LIVEKIT_API_SECRET
            );

            const egresses = await egressClient.listEgress({ roomName });
            
            return egresses
                .filter(e => e.roomName === roomName)
                .map(recording => ({
                    recordingId: recording.egressId,
                    status: this.getEgressRecordingStatus(recording.status),
                    startedAt: recording.startedAt ? new Date(Number(recording.startedAt) / 1000000).toISOString() : null,
                    endedAt: recording.endedAt ? new Date(Number(recording.endedAt) / 1000000).toISOString() : null,
                    duration: recording.file?.duration || 0,
                    outputUrl: recording.file?.filename ? 
                        `https://${process.env.AWS_BUCKET_NAME || 'agilemeets-meetings'}.s3.eu-central-1.amazonaws.com/${recording.file.filename}` : 
                        null
                }));
        } catch (error) {
            logger.error('Error getting recordings:', error);
            throw new AppError(500, 'Failed to get recordings');
        }
    }

    async getRecordingStatus(roomName) {
        try {
            logger.info(`Getting recording status for room: ${roomName}`);
            
            const egressClient = new EgressClient(
                LIVEKIT_URL,
                LIVEKIT_API_KEY,
                LIVEKIT_API_SECRET
            );

            const egresses = await egressClient.listEgress({ 
                roomName,
                active: true
            });

            if (!egresses || egresses.length === 0) {
                return {
                    isRecording: false,
                    recordingId: null,
                    status: null
                };
            }

            const activeRecording = egresses[0];
            return {
                isRecording: true,
                recordingId: activeRecording.egressId,
                status: this.getEgressRecordingStatus(activeRecording.status),
                startedAt: new Date(Number(activeRecording.startedAt) / 1000000).toISOString(),
                outputUrl: activeRecording.file?.filename ?
                    `https://${process.env.AWS_BUCKET_NAME || 'agilemeets-meetings'}.s3.eu-central-1.amazonaws.com/${activeRecording.file.filename}` :
                    null
            };
        } catch (error) {
            logger.error('Error getting recording status:', error);
            throw new AppError(500, 'Failed to get recording status');
        }
    }

    getEgressRecordingStatus(status) {
        const statusMap = {
            0: 'EGRESS_STARTING',
            1: 'EGRESS_ACTIVE',
            2: 'EGRESS_ENDING',
            3: 'EGRESS_COMPLETE',
            4: 'EGRESS_FAILED',
            5: 'EGRESS_ABORTED',
            6: 'EGRESS_LIMIT_REACHED'
        };
        return statusMap[status] || 'UNKNOWN';
    }

    async generateToken(roomName, identity, metadata = {}) {
        try {
            // Verify room exists
            const room = await this.getActiveRoom(roomName);
            if (!room) {
                throw new AppError(404, 'Room not found');
            }

            // Create token with permissions
            const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
                identity,
                name: metadata.name || identity,
                metadata: JSON.stringify(metadata)
            });

            at.addGrant({
                roomJoin: true,
                room: roomName,
                canPublish: true,
                canSubscribe: true,
                canPublishData: true
            });

            return at.toJwt();
        } catch (error) {
            logger.error('Error generating token:', error);
            throw new AppError(500, 'Failed to generate token');
        }
    }
}

module.exports = new RoomService(); 