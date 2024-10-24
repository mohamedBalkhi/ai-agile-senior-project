namespace Senior.AgileAI.BaseMgt.Application.Common
{
    #nullable disable

    public class ApiResponse
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }
        public object Data { get; set; }

        public ApiResponse(int statusCode, string message, object data = null)
        {
            StatusCode = statusCode;
            Message = message;
            Data = data;
        }
    }
}
