public without sharing class Utils 
{
    public static Boolean isSandbox
    {
        get
        {
            if(isSandbox == null)
            {
                isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return isSandbox;
        }
        private set;
    }
    
    public static String getCurrentOrgName()
    {
        System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
        
        return domain.getSandboxName() == null ? 'Production' : domain.getSandboxName();
    }

}