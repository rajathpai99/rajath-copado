public class AccCreation {
    public static void newAccountRecords() {
        try{
        List<Account> accList= new List<Account>();
        for( Integer i=0 ; i<20 ; i++ ) {
            Account acnt1=new Account();
            acnt1.Name = 'PaiCopa'+i+'Rajath';
            acnt1.Fax = '123paicopa';
            acnt1.Website='https://trailhead.salesforce.com';
            accList.add(acnt1);
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