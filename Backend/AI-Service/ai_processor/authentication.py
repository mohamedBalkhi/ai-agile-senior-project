from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.conf import settings
from functools import wraps
from rest_framework.response import Response
from rest_framework import status


class APIKeyAuthentication(BaseAuthentication):
    """
    Custom authentication class for API Key-based authentication.
    """

    def authenticate(self, request):
        print("step01: auth")
        api_key = request.headers.get('X-API-KEY')
        if not api_key:
            raise exceptions.AuthenticationFailed('No API key provided')
        print(api_key)
        print(getattr(settings, 'API_KEYS_SERVICE', ''))
        if api_key != getattr(settings, 'API_KEYS_SERVICE', ''):
            raise exceptions.AuthenticationFailed('Invalid or unauthorized API key')
        print("step01 Done")
        return (None, None)


def require_api_key(view_func):
    """
    Decorator to enforce API Key authentication for specific views.
    """

    @wraps(view_func)
    def decorated_view(view_instance, request, *args, **kwargs):
        api_key = request.headers.get('X-API-KEY')

        if not api_key:
            return Response(
                {'error': 'No API key provided'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if api_key != getattr(settings, 'API_KEYS_SERVICE', ''):
            return Response(
                {'error': 'Invalid or unauthorized API key'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        return view_func(view_instance, request, *args, **kwargs)

    return decorated_view
