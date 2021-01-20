public class AccCreation{
    public static void newAccountRecords() {
        try{
        List<Account> accList= new List<Account>();
        for( Integer i=0 ; i<20 ; i++ ) {
            Account act=new Account();
            act.Name = 'PaiCopa'+i+'Rajath';
            act.Fax = '123paicopa';
            act.Website='https://trailhead.salesforce.com';
            accList.add(act);
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