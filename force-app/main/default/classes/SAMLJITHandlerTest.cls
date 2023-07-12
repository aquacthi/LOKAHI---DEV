@isTest
private class SAMLJITHandlerTest {

    @testsetup
    public static void setUp(){
        
        Profile profId = [Select Id From Profile Where Name = 'System Administrator'];    

        User tuser1 = new User(firstname = 'Test',
                              lastName = 'User1',
                              Email = 'testuser1@test.com',
                              Username = 'testuseru1@test.com',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = 'Utest1',
                              Title = 'Mr.',
                              AboutMe = 'test1',
                              Street = 'James Street',
                              State = 'Dallas',
                              City = 'Washington DC',
                              Country = 'USA',
                              MobilePhone = '(245)353453',
                              Department = 'Test',
                              Division = 'Test1',
                              EmployeeNumber = '232423',
                              Extension = '1233242345',
                              Fax = '3353453',
                              CompanyName = 'AMZ',   
                              FederationIdentifier='232423',
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              isActive = true,
                              Phone = '(344) 3353 444',
                              ProfileId = profId.Id);
        
        insert tuser1;
        
        Account a = new Account(
            Name = 'Amazon'
        );
        insert a;
        
        Contact con1 = new Contact(LastName= 'test Con1',
                                   Employee_Id__c='232423',
                                   AccountId=a.Id,
                                   Email = 'amazon@amz.com',
                                   Department = '1500');
        
        insert con1;
        
    }
    
    @isTest
    public static void Test1(){
        Account a = [SELECT Id, Name FROM Account LIMIT 1];
        a.Name = 'Amazon';
        update a;
        System.debug('## role : ' + [Select Id, DeveloperName From UserRole]);
        List<User> userList  = [Select Id,FirstName,Profile.Id,LastName,Alias,Title,AboutMe,Street,State,City,Country,Department,MobilePhone,Division,EmployeeNumber,Extension,Fax,CompanyName,Email,Phone,FederationIdentifier From User Where Email = 'testuser1@test.com'];
        List<Contact> conList = [SELECT Employee_Id__c,Id,Name FROM Contact];
            
        Map<String, String> attributes = new Map<String, String>();
        attributes.put('GIVEN_NAME',userList[0].FirstName);
        attributes.put('EMAIL',userList[0].Email);
        attributes.put('FAMILY_NAME',userList[0].LastName);
         
        Test.Starttest();       
        SAMLJITHandler suh = new SAMLJITHandler();
        suh.createUser(null,null,null,'999999999',attributes,'Test');
        try{
            suh.updateUser(userList[0].Id,null,null,null,'999999999',attributes,'Test');
        } catch (Exception e) {
            // catch exception
        }
        Test.stopTest();
    }
}