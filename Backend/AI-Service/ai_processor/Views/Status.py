from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ..models import AudioProcessing
from django.core.exceptions import ObjectDoesNotExist
from ai_processor.authentication import require_api_key

#? Second Api in the processing flow, need to be called in a frequency of time.
class StatusAPIView(APIView):
    @require_api_key
    def get(self, request, audio_token):
        try:
            # Get the audio processing record from DB
            audio_task = AudioProcessing.objects.get(audio_token=audio_token)
            is_done = audio_task.processing_status == 'COMPLETED'
            
            return Response({
                'done': is_done,
                'status': audio_task.processing_status
            }, status=status.HTTP_200_OK)
            
        except ObjectDoesNotExist:
            return Response({
                'error': 'Audio processing task not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        except Exception as e:
            return Response({
                'error': f'Failed to retrieve status: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
