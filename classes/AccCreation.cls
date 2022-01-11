public class AccCreation {
    public static void newAccountRecords() {
        try{
        List<Account> accList= new List<Account>();
        for( Integer i=0 ; i<20 ; i++ ) {
            Account act1_upd=new Account();
            act1_upd.Name = 'PaiCopa'+i+'Rajath';
            act1_upd.Fax = '123paicopa';
            act1_upd.Website='https://twitter.com';
            accList.add(act1_upd);
            //test comment 29Dec21 v1
            //test comment 29Dec21 v2
        }
        if(accList.size() > 0) {
            insert  accList;
            //test comment 16Sep21
        }
    }
    catch(Exception ex){

    }
    }
}