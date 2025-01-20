enum AIProcessingStatus {
  notStarted,  // Initial state
  onQueue,     // Submitted to AI service
  processing,  // AI service is processing
  completed,   // Processing completed successfully
  failed       // Processing failed
}
