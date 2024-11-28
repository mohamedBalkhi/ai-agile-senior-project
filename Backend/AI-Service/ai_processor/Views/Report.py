from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ..models import AudioProcessing
from django.core.exceptions import ObjectDoesNotExist
from ai_processor.authentication import require_api_key


#? Third Api in the processing flow, need to be called only once the processing is completed.
class ReportAPIView(APIView):
    @require_api_key

    def get(self, request, audio_token):
        try:
            audio_task = AudioProcessing.objects.get(audio_token=audio_token)
            
            # Return the full report
            report = {
                'audio_id': str(audio_task.audio_token),
                'transcript': audio_task.transcript,
                'summary': audio_task.summarization,
                'key_points': audio_task.key_points,
            }
            
            return Response(report, status=status.HTTP_200_OK)
            
        except ObjectDoesNotExist:
            return Response({
                'error': 'Audio not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        except Exception as e:
            return Response({
                'error': f'Failed to retrieve report: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
