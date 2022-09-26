public class APIGatewayWrapper 
{

    public Boolean hasError { get; set;}
    public String message { get; set;}
    public String statusCode { get; set;}
    public String recordId { get; set;}
    public String metadataName { get; set;}
    public String customEndpoint { get; set;}
    public String payload { get; set;}
    public Httpresponse response { get; set;}
    public API_Gateway__mdt apiGatewayRecord { get; set;}
    public Map<String, String> mapHeaders { get; set;}
    public String orgName { get; set;}
    public Boolean isSandbox { get; set;}
    
    public APIGatewayWrapper()
    {
        this.hasError=false;
        this.mapHeaders = new Map<String, String>();
        this.orgName = Utils.getCurrentOrgName();
        this.isSandbox = Utils.isSandbox;
        
    }

}