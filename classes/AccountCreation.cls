public class AccountCreation {
    public static void newAccountRecords() {
        try{
        List<Account> accList= new List<Account>();
        for( Integer i=0 ; i<20 ; i++ ) {
            Account acc=new Account();
            acc.Name = 'PaiRajath'+i;
            acc.AccountNumber = '12345'+i;
            acc.Fax = '123paicopa';
            acc.Website='https://trailhead.salesforce.com';
            acc.Phone = '992211'+i;
            accList.add(acc);
        }
        if(accList.size() > 0) {
            insert  accList;
        }
    }
    catch(Exception ex){
        system.debug('Exception_Line_No--->'+ex.getLineNumber());
        system.debug('Exception_Message--->'+ex.getMessage());
    }
    }
}