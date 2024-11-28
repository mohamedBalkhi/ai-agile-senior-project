from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ai_processor.models import AudioProcessing
from ai_processor.Queue.Producer import AudioQueueProducer
import uuid
from django.utils import timezone
from ai_processor.authentication import require_api_key

    

#? First Api in the processing flow..

class SubmitAudioAPIView(APIView):

    @require_api_key
    def post(self, request):
        print("step02: submit audio")

        #? Get required and optional parameters from the request
        audio_url = request.data.get("audio_url")
        main_language = request.data.get("main_language") or "en"
        user_plan = request.data.get("user_plan") or "basic"

        # Validate that audio_url is provided
        if not audio_url:
            return Response({"error": "audio_url is required."}, status=status.HTTP_400_BAD_REQUEST)
        if not main_language:
            return Response({"error": "main_language is required."}, status=status.HTTP_400_BAD_REQUEST)
        if not user_plan:
            return Response({"error": "user_plan is required."}, status=status.HTTP_400_BAD_REQUEST)

        #? Create a new audio processing document in the database
        audio_document = AudioProcessing.objects.create(
            audio_token = uuid.uuid4(),
            main_language=main_language,
            user_plan=user_plan,
            created_at=timezone.now(),
            updated_at=timezone.now(),
            processing_status='ON_QUEUE',
            audio_url=audio_url,
            key_points=[]
        )
        print("step03: create audio task")
        #? Send the task to RabbitMQ
        try:
            producer = AudioQueueProducer()
            producer.add_audio_task(
                audio_id=audio_document.audio_token,
                audio_url=audio_url,
                main_language=main_language,
                user_plan=user_plan
            )
            # producer.close()
            print("step04: send to queue")

        except Exception as e:
            #? Update the status to FAILED if the task couldn't be sent to the queue
            audio_document.processing_status = 'FAILED'
            audio_document.save()
            return Response(
                {"error": "Failed to process audio", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        #? Return the audio token in the success response
        return Response({
            "message": "Audio processing task submitted successfully",
            "audio_token": str(audio_document.audio_token)
        }, status=status.HTTP_201_CREATED)
