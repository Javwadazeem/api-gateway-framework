public class APIGateway 
{
    
    public static APIGatewayWrapper initiateCallout(String metadataName, String payload
                                                    , String customEndpoint
                                                    , Map<String, String> mapHeaders)
    {
        APIGatewayWrapper instance = new APIGatewayWrapper();
        
        try
        {
            if(String.isBlank(metadataName)) 
            	throw new APIGatewayException(m_ERROR_MESSAGE.get('NO_MD_NAME'));
            
            instance.metadataName = metadataName;
            instance.payload = payload;
            instance.mapHeaders = mapHeaders;
            instance.customEndpoint =customEndpoint;
            
            getAPIGatewayRecord(instance);
            
            if(instance.hasError) return instance;
            
            makeCallout(instance);
        }
        catch(Exception ex)
        {
            buildError(instance, ex.getMessage(), '');
        }
        return instance;
    }
    
    private static void getAPIGatewayRecord(APIGatewayWrapper instance)
    {
        for(API_Gateway__mdt objGateway : [Select DeveloperName, MasterLabel, is_Custom_Endpoint__c 
                                           , is_Compressed__c, Method__c
                                           , Endpoint__c, Named_Credential__c
                                           , Timeout__c, is_Production__c
                                           FROM API_Gateway__mdt 
                                           where DeveloperName =: instance.metadataName
                                           AND Active__c = TRUE 
                                           AND is_Production__c !=: instance.isSandbox LIMIT 1])
        {
            instance.apiGatewayRecord =objGateway;
        }
        
        if(instance.apiGatewayRecord == null )
            throw new APIGatewayException(m_ERROR_MESSAGE.get('NO_API_GATEWAY'));
        else if(instance.apiGatewayRecord.Method__c != 'GET' && String.isBlank(instance.payload) ) 
            throw new APIGatewayException(m_ERROR_MESSAGE.get('PAYLOAD_NULL'));
    }
    
    private static void makeCallout(APIGatewayWrapper instance)
    {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        buildRequest(instance, request);
        
        if(instance.hasError) return;
        
        response = performRequest(instance, request);
        
        
        checkForError(instance, response);
    }
    private static void buildRequest(APIGatewayWrapper instance, HttpRequest request)
    {
        request.setEndpoint(buildEndpoint(instance));
        
        Integer timeout = instance.apiGatewayRecord.Timeout__c != null
                        ? (Integer)instance.apiGatewayRecord.Timeout__c
                        : 30000;
        request.setTimeout(timeout);
        request.setMethod(instance.apiGatewayRecord.Method__c);
        request.setCompressed(instance.apiGatewayRecord.is_Compressed__c);
        if(instance.payload != null) request.setBody(instance.payload);

        buildHeaders(instance, request);
    }
    private static HttpResponse performRequest(APIGatewayWrapper instance, HttpRequest request)
    {
        Http httpInstance = new Http();
        HttpResponse response = new HttpResponse();
		response = httpInstance.send(request);
        
        if(response != null ) 
        {
            instance.response = response;
        	instance.statusCode = String.valueOf(response.getStatusCode());
        }
        return response;
    }
    private Static String buildEndpoint(APIGatewayWrapper instance)
    {
        String strEndpoint ='';
        String strTempEndpoint = instance.apiGatewayRecord.is_Custom_Endpoint__c 
                                ? instance.customEndpoint 
                                : instance.apiGatewayRecord.Endpoint__c;
        
        if(String.isBlank(strTempEndpoint))
            throw new APIGatewayException( m_ERROR_MESSAGE.get('ENDPOINT_MISSING') );
        
        strEndpoint = 'callout:'+instance.apiGatewayRecord.Named_Credential__c
            					+strTempEndpoint;
        return strEndpoint;
    }
    
    private static void buildHeaders(APIGatewayWrapper instance, HttpRequest request )
    {
        if(instance.mapHeaders == null || instance.mapHeaders.isEmpty()) return;
        
        for(String key : instance.mapHeaders.keySet())
        {
            request.setHeader(key, instance.mapHeaders.get(key));
        }
    }
    
    public static APIGatewayWrapper buildError(APIGatewayWrapper instance, String message, String code)
    {
        instance.hasError = True;
        instance.message =message;
        instance.statusCode = String.isBlank(instance.statusCode) ? code : instance.statusCode;
        return instance;
    }
    
    private static void checkForError(APIGatewayWrapper instance, HttpResponse response)
    {
        Set<Integer> statusCodes = new Set<Integer>{200,201,202,203};
          
        if(!statusCodes.contains(response.getStatusCode()))
        {
            instance.statusCode = String.valueOf( response.getStatusCode() );
            throw new APIGatewayException(m_ERROR_MESSAGE.get('FAILED'));
        }
        else if(String.isBlank(response.getBody()))
        {
            instance.statusCode = String.valueOf( response.getStatusCode() );
            throw new APIGatewayException( m_ERROR_MESSAGE.get('EMPTY_RESPONSE') );
        }
    }
    
    private static Map<String, String> m_ERROR_MESSAGE
    {
        get
        {
            if(m_ERROR_MESSAGE == null)
            {
              m_ERROR_MESSAGE = new Map<String, String>
                                {
                                    'PAYLOAD_NULL' => 'No Payload Found!'
                                  , 'NO_API_GATEWAY' => 'API Gateway record not found.'
                                  , 'FAILED' => 'Callout Failed'
                                  , 'EMPTY_RESPONSE' => 'Response has Empty Body.'
                                  , 'NO_MD_NAME' => 'No Metadata name found for this Callout.'
                                  , 'ENDPOINT_MISSING' => 'No Endpoint found to make this callout.'
                                };
            }
            return m_ERROR_MESSAGE;
        }
        private set;
    }
    public class APIGatewayException extends Exception {}
}