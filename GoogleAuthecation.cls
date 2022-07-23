public without sharing class GoogleAuthecation {

    public static googleWithSalesforce__c googleAuth = googleWithSalesforce__c.getOrgDefaults();
    // public static googleWithSalesforce__c googleAuth=[SELECT Client_ID__c, Client_secret__c From googleWithSalesforce__c LIMIT 1];
    // System.debug(googleAuth);
    private static String key = googleAuth.Client_ID__c;
    private static String secret = googleAuth.Client_secret__c;
    private static String redirect_uri= 'https://demolivelaunch-developer-edition.ap27.force.com/GoogleIntegration/s';
    // private static String redirect_uri= ' https://cloudanalogycom311-dev-ed.lightning.force.com/c/googleDriveApp.app';
    private static String tokenUrl='https://accounts.google.com/o/oauth2/token';
    
    @AuraEnabled
    public Static String createAuthenticationURL() {
        String key = EncodingUtil.urlEncode(key,'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri,'UTF-8');
        String authuri = '';
        authuri =  'https://accounts.google.com/o/oauth2/v2/auth?'+
        'client_id='+key+
        '&response_type=code'+
        '&scope=https://www.googleapis.com/auth/drive'+
        '&redirect_uri='+uri+
        '&access_type=offline'+
        '&include_granted_scopes=true'+
        '&prompt=consent';
        return authuri;

    }

    @AuraEnabled
    public static driveWrapper getaccessTokenorRefreshToken (String code){
        try {
            driveWrapper dwData=new driveWrapper();
            String token;
       
            Datetime dTime = Datetime.now();
            Integer getoffset = UserInfo.getTimezone().getOffset(dTime);
            Datetime hitTime = dTime.addSeconds(getoffset/1000);

            System.debug('hitTime==>>'+hitTime);
            System.debug('googleAuth.Expire_Date_Time__c==>>'+googleAuth.Expire_Date_Time__c);
            if(googleAuth.Auth_code__c == code && googleAuth.Expire_Date_Time__c >  hitTime){
                System.debug('firstIfCondition');
                token = googleAuth.access_token__c;
            }else if(googleAuth.Expire_Date_Time__c < hitTime ){
                System.debug('else ifCondition');
                String messageBody = 
                    '&client_id='+key+
                    '&client_secret='+ secret+    
                    '&refresh_token='+googleAuth.refresh_token__c+
                    '&grant_type=refresh_token';
    
                    dwData = getAccessToken(messageBody , code);
            }else{ 
                String messageBody = 'code='+code+
                    '&client_id='+googleAuth.Client_Id__c+
                    '&client_secret='+googleAuth.Client_secret__c+
                    '&redirect_uri='+redirect_uri+
                    '&grant_type=authorization_code';
                
                    dwData = getAccessToken(messageBody, code);
            }
            
           return dwData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static driveWrapper getAccessToken(String messageBody, String code){
        driveWrapper dw=new driveWrapper();
        Datetime dTime = Datetime.now();
        Integer getoffset = UserInfo.getTimezone().getOffset(dTime);
        Datetime hitTime = dTime.addSeconds(getoffset/1000);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type',  'application/x-www-form-urlencoded');
        // String messageBody ='code='+code+
        // '&client_id='+key+
        // '&client_secret='+secret+
        // '&redirect_uri='+redirect_uri+
        // '&grant_type=authorization_code';
        request.setHeader('Content-length', String.valueOf(messageBody.length()));
        request.setBody(messageBody);
        request.setTimeout(60*1000);
       system.debug('messageBody:'+messageBody);
       Http callout = new Http();
       String responseText;
       HttpResponse response = callout.send(request);
       String token;
       String data;

      System.debug('googleAuth'+googleAuth);

       if(response.getStatusCode() == 200) {

           responseText = response.getBody();
           system.debug('responseText:'+responseText);
           Map<String,object> responseMap =(Map<String,object>)JSON.deserializeUntyped(responseText) ;  
            token =  String.valueOf(responseMap.get('access_token'));
            googleAuth.access_token__c = token;
            dw.token=token;
            System.debug('refresh_token__c '+String.valueOf(responseMap.get('refresh_token')));
            System.debug('expires_in__c '+String.valueOf(responseMap.get('expires_in')));
            
            googleAuth.refresh_token__c = String.valueOf(responseMap.get('refresh_token'));
            String expiresIn = String.valueOf(responseMap.get('expires_in'));
            googleAuth.Auth_code__c = code;
            Integer expireTime = Integer.valueOf(expiresIn);
            Datetime TokenexpireTime = hitTime.addSeconds(expireTime); 
            System.debug('Decimal.valueOf(expiresIn)==>>'+Decimal.valueOf(expiresIn));
            googleAuth.expires_in__c = Decimal.valueOf(expiresIn);
            googleAuth.Expire_Date_Time__c=TokenexpireTime;
           system.debug('token:'+token);
           system.debug('responseMap'+responseMap);
           Set<String> newSet =  new Set<String>();
           newSet = responseMap.keySet();
           system.debug('newSet:'+newSet);
           System.debug('googleAuth '+googleAuth);
        
           data = getFile(token);
           dw.data=data;
           update googleAuth;
       }
         
       return dw;

    }

    @AuraEnabled
    public static String getFile(String token) {
         System.debug('token' +token);
         Http http = new Http();
         HTTPResponse response = new HTTPResponse();
         HttpRequest request = new HttpRequest();
         request.setEndpoint('https://www.googleapis.com/drive/v2/files');
         request.setMethod('GET');
         request.setHeader('Authorization', 'Bearer ' + token);
         response = http.send(request);
         String res;
         if(response.getStatusCode() == 200) {
            System.debug(response.getBody());
            // List<String> res=new List<String>();
             res=response.getBody();
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug(results); 
                
        }
        return res;
    }
    
    @AuraEnabled
    public static String uploadFile(String attachmentId, String accessToken, String type) {
        System.debug('attachmentId'+attachmentId);
        System.debug('accessToken'+accessToken);
        System.debug('type'+type);
        ContentVersion cvFile = [SELECT VersionData,FileType,title,ContentDocumentId FROM ContentVersion WHERE Id =: attachmentId Limit 1];
        // Blob myBlob = cvFile[0].VersionData;
        System.debug('cvFile'+cvFile);
        String fileName=cvFile.title;
        
        //String fileExtension = fileName.substring(fileName.indexOf('.')+1, fileName.length());
        String boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        String delimiter = '\r\n--' + boundary + '\r\n';
        String close_delim = '\r\n--' + boundary + '--';
        String url = 'https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart';
        // string authorizationHeader = 'Bearer' + accessToken; 
        String contentType = cvFile.FileType;
        
        if (contentType == 'JPG' || contentType == 'JPEG' || contentType == 'PNG') {
            contentType = 'image/' + contentType;
          } else if (contentType == 'PDF') {
            contentType = 'application/' + contentType;
          } else if (contentType == 'TEXT') {
            contentType = 'text/plain';
          } else if (contentType == 'XML') {
            contentType = 'text/xml';
          }
          else if(contentType =='mp4'){
            contentType = 'video/'+contentType;
          }
        // String ContentType= type;
        System.debug('cvFile.VersionData'+cvFile.VersionData);
        String bodyEncoded = EncodingUtil.base64Encode(cvFile.VersionData);
        String body =  delimiter + 'Content-Type: application/json\r\n\r\n' + '{ "title" : "' + fileName + '",' + ' "mimeType" : "' + contentType + '" }' + delimiter + 'Content-Type: ' + contentType + '\r\n' + 'Content-Transfer-Encoding: base64\r\n' + '\r\n' + bodyEncoded + close_delim;       
        // Integer contentSize = myBlob.size();
        System.debug('body '+body);
        // System.debug('authorizationHeader'+authorizationHeader);
    //     HttpRequest req = new HttpRequest();
    //     req.setHeader('Authorization', 'Bearer ' + accessToken);
    //     req.setheader('Content-Type','multipart/mixed; boundry="'+boundary +'"');
    //     req.setheader('Content-Length',String.valueOf(body.length()));
    //     req.setBody(body);
    //     req.setMethod('POST'); 
    //     req.setEndpoint(url); 
    //     // req.setBodyAsBlob(myBlob); 
    //     Http h = new Http(); 
      
        
    //    System.debug('resp'+resp);
    //    System.debug('resp'+resp.getBody());
        Http https = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'multipart/mixed; boundary="' + boundary + '"');
        req.setHeader('Content-length', String.valueOf(body.length()));
        req.setBody(body);
        req.setMethod('POST');
        System.debug('Req--->'+req);
        HttpResponse response = https.send(req);
        System.debug('Response====>'+response);
	   //After file was successfully upload we delete the file
    //    delete new ContentDocument(Id = cvFile.ContentDocumentId);
    //    delete [SELECT Id from ContentDocument WHERE Id =: cvFile.ContentDocumentId];
    //    if(response.getStatusCode() == 200) {
        return String.valueOf(response.getStatuscode());
    //    }

      
    }

    

    @AuraEnabled
   
    public static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
          insert cv;
          return cv;
        } catch(DMLException e) {
          System.debug(e);
          return null;
        }
      }
   

    public class driveWrapper{
        @AuraEnabled
        public string token;
        @AuraEnabled
        public string data;
    }

   
}
