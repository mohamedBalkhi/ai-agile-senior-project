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
        print("step02: master processor")

        audio_file_path = None
        try:
            audio_task = AudioProcessing.objects.get(audio_token=audio_id)
            
            # Download the audio file to the AUDIOS_FOLDER
            audio_file_path, file_format = download_audio_to_storage(audio_url, audio_id)
            print(f"Audio file downloaded successfully to: {audio_file_path}")

            # Step 2: Speech-to-Text
            transcript = self.speech_to_text_strategy.convert_speech_to_text(audio_file_path)
            audio_task.transcript = transcript
            audio_task.processing_status = 'STT_PROCESSED'
            audio_task.save()
            print(f"Transcript completed!")

            # Step 3: Summarization
            summary = self.summarization_strategy.summarize_text(transcript)
            audio_task.summarization = summary
            audio_task.processing_status = 'SUMMARY_PROCESSED'
            audio_task.save()
            print(f"Summary completed!")

            # Step 4: Key Points Extraction
            key_points = self.key_points_strategy.extract_key_points(transcript)
            print (key_points)
            
            # Split key points into sentences if it's a string
            if isinstance(key_points, str):
                key_points = TextSplitter.split_into_sentences(key_points)

                print (key_points)
            
            audio_task.key_points = key_points
            audio_task.processing_status = 'KEY_POINTS_PROCESSED'
            
            audio_task.save()
            print(f"Key Points extraction completed!")

            # Final status update
            audio_task.processing_status = 'COMPLETED'
            audio_task.save()
            print("step07: master processor completed")

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
            # Clean up the audio file after processing
            if audio_file_path:
                cleanup_audio_file(audio_file_path)

    def format_results(self, audio_id, transcript, summary, key_points):
        return {
            "audio_id": audio_id,
            "transcript": transcript,
            "summary": summary,
            "key_points": key_points
        }
