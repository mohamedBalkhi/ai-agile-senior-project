from ..models import AudioProcessing
from django.core.exceptions import ObjectDoesNotExist
from .audio_downloader import download_audio_to_storage, cleanup_audio_file
from .text_splitter import TextSplitter

#? master processor class
#? pipeline of the audio processing


class MasterProcessor:
    def __init__(self, speech_to_text_strategy, summarization_strategy, key_points_strategy):
        self.speech_to_text_strategy = speech_to_text_strategy
        self.summarization_strategy = summarization_strategy
        self.key_points_strategy = key_points_strategy

    def process_task(self, task):
        audio_id = task["audio_id"]
        audio_url = task["audio_url"]
        print(f"Processing Audio ID: {audio_id}")
        print(f"Processing Audio URL: {audio_url}")
        print("step02: master processor")

        audio_file_path = None
        try:
            audio_task = AudioProcessing.objects.get(audio_token=audio_id)
            
            # Download the audio file to the AUDIOS_FOLDER
            audio_file_path, file_format = download_audio_to_storage(audio_url, audio_id)
            print(f"Audio file downloaded successfully to: {audio_file_path}")


            transcript = self.speech_to_text_strategy.convert_speech_to_text(audio_file_path)
            audio_task.transcript = transcript
            audio_task.processing_status = 'STT_PROCESSED'
            audio_task.save()
            print(f"Transcript completed!")

            # Step 3: Summarization
            print(task["main_language"])
            
            summary = self.summarization_strategy.summarize_text(transcript, task["main_language"])
            audio_task.summarization = summary
            audio_task.processing_status = 'SUMMARY_PROCESSED'
            audio_task.save()
            print(f"Summary completed!")    

            # Step 4: Key Points Extraction
            key_points = self.key_points_strategy.extract_key_points(summary) 
            print(f"Key points: {key_points} in the master processor")          
            key_points = TextSplitter.split_into_sentences(key_points)
            print(f"Key points after splitting: {key_points}")
            key_points = [point for point in key_points if point and point.strip()]
            print(f"Key points after cleaning: {key_points}")
            
            # Ensure key_points is always a list, even if empty
            if not isinstance(key_points, list):
                key_points = []
                
            print(f"Processed key points: {key_points}")
            
            audio_task.key_points = key_points
            audio_task.processing_status = 'KEY_POINTS_PROCESSED'
            audio_task.save()
            print(f"Key Points extraction completed!")

            # Final status update
            audio_task.processing_status = 'COMPLETED'
            audio_task.save()
            print("step07: master processor completed")
            cleanup_audio_file
            return self.format_results(audio_id, transcript, summary, key_points)

    
        except ObjectDoesNotExist:
            print(f"Audio task with ID {audio_id} not found in database")
            raise
        except Exception as e:
            if 'audio_task' in locals():
                audio_task.processing_status = 'FAILED'
                audio_task.error_message = str(e)
                audio_task.save()
            print(f"Error processing task {audio_id}: {str(e)}")
            raise e
        finally:
            if audio_file_path:
                cleanup_audio_file(audio_file_path)


    def format_results(self, audio_id, transcript, summary, key_points):
        return {
            "audio_id": audio_id,
            "transcript": transcript,
            "summary": summary,
            "key_points": key_points
        }
