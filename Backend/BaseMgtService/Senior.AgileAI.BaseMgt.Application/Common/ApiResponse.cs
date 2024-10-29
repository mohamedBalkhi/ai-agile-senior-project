namespace Senior.AgileAI.BaseMgt.Application.Common
{
    #nullable disable

    public class ApiResponse<T>
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }
        public T Data { get; set; }

        public ApiResponse(int statusCode, string message, T data = default)
        {
            StatusCode = statusCode;
            Message = message;
            Data = data;
        }
    }

    // Non-generic version for backwards compatibility
    public class ApiResponse : ApiResponse<object>
    {
        public ApiResponse(int statusCode, string message, object data = null) 
            : base(statusCode, message, data)
        {
        }
    }
}
