namespace Senior.AgileAI.BaseMgt.Application.Common
{
    #nullable disable

    public class ApiResponse<T>
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }
        public T Data { get; set; }
        public string Error { get; set; }
        public Dictionary<string, string> Errors { get; set; } = new Dictionary<string, string>();

        public ApiResponse()
        {
        }

        public ApiResponse(int statusCode, string message, T data = default, string error = null, Dictionary<string, string> errors = null)
        {
            StatusCode = statusCode;
            Message = message;
            Data = data;
            Error = error;
            Errors = errors;
        }
    }

    // Non-generic version for backwards compatibility
    public class ApiResponse : ApiResponse<object>
    {
        public ApiResponse(int statusCode, string message, object data = null, string error = null, Dictionary<string, string> errors = null) 
            : base(statusCode, message, data, error, errors)
        {
        }
    }
}
