
/**
* @description Class containing all methods interacting with the Opportunity object
* ----------------------
* Date         Version     JIRA        Author  Description
*                          CRM-1000    IME
* 26/02/2019  R6C0P1       CRM-1402    GDR     Suppression du filtre Catégorie personne lors de l'envoi de mail
* 02/08/19    R9           CRM-1680    GDR     nouveau champ DigitalScore__c à transférer sur la fiche personne physique
* 04/10/19    R10          CRM-1750    YRU     nouveau champ OFFirstContactDate__c à transférer sur la fiche personne physique
* 05/02/20    R12          CRM-2110    YRU     CloseCase related to Opportunity if close the opp
* 24/04/20    R13          CRM-2157    FAZ     Nouvelle Méthode UpdateTecloOptinAccount pur la Màj des optins données Telco et facture Telco sur la fiche personne
* 26/05/20    R12C2        CRM-2432    GDR     rework methodes closeCaseOppSansSuiteRefuse et updateCaseOwnerAccountOpen pour cibler les cases à updater
* 12/06/20      R13     CRM-2335    FAZ     Mise en place d'une règle sur l'étape de vente de l'opportunité pour gérer le score de fraude Isoft
* 15/06/20      R13C0       CRM-2467    LK      Erreurs PB28 du 09/06/2020
* 20/06/20    R14    CRM-2467  LK    Erreurs PB28 du 09/06/2020
* 08/08/2020   R14			CRM-2557	GDR		Synchronisation des souscripteurs Crédit Immo
*/


public with sharing class AP08OpportunityUtils {
    
    /**
    * @author Juan Manuel Jimenez
    * @creation 30/11/2016
    * @description fill opportunity Name
    * @param oppsToinsert list of opportunities to change the name
    */
    public static void formatOpportunityName(Map<Id, Opportunity> oppsToInsert) {
        List<String> recordTypesAccs = new List<String> {'Person', 'PersonProspect', 'Institution'};
            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, recordtypeID, FirstName, LastName, Name FROM Account WHERE RecordType.DeveloperName IN :recordTypesAccs AND 
                                                                Id IN :oppsToInsert.keySet()]);
        
        for (Opportunity opp : oppsToInsert.values()) {
            String offerName = '';
            if (accountMap.get(opp.AccountId) != null) {
                if (opp.RecordType.developerName != 'OBTracing' && opp.CommercialOfferName__c != null){
                    offerName = ' - ' + opp.CommercialOfferName__c;
                }
                else {
                    offerName = ' - ' + getLabel(opp.TracingProduct__c);
                }
                //opp.Name = accountMap.get(opp.AccountId).FirstName + ' ' + accountMap.get(opp.AccountId).LastName + offerName;
                if (accountMap.get(opp.AccountId).RecordTypeId != Label.AccountRTIdProspectMoral){
                    opp.Name = accountMap.get(opp.AccountId).FirstName + ' ' + accountMap.get(opp.AccountId).LastName + offerName;
                }
                else {
                    opp.Name = accountMap.get(opp.AccountId).Name + offerName;
                }
            }
        }
    }
    
    public static String getLabel(String code) {
        List<Schema.Picklistentry> plvs = opportunity.TracingProduct__c.getDescribe().getPicklistValues();
        system.debug('myplvs:'+plvs);
        for (Schema.Picklistentry plv : plvs) {
            if (plv.getValue() == code) {
                system.debug('myplv:'+plv.getValue());
                return plv.getLabel();
            }
        }
        return null;
    }
    
    /**
    * @author Gaspard Etienne
    * @creation 02/01/2017
    * @description Send an email alert to prospect to continue enrolment process
    */
    public static void sendMailOpportunity(Set<Id> oppsToSendMail, Id templateId) {
        List<Messaging.Email> mailList = new List<Messaging.Email>();
        /* GDR CRM-1402 Begin */
        /*Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>([SELECT Id, Account.PersonContactId, Account.Type FROM Opportunity WHERE Account.Type = '02' AND Id in:oppsToSendMail]);*/
        Map<Id, OpportunityContactRole> mapOpp = new Map<Id, OpportunityContactRole>([SELECT Opportunity.Id, Contact.Id, Opportunity.Account.Type FROM OpportunityContactRole 
                                                                                        WHERE opportunity.id in:oppsToSendMail]);
        /* GDR CRM-1402 End */
        try {
            for (Id oppId : mapOpp.keySet()) {
                Messaging.SingleEmailMessage userMessage = new Messaging.SingleEmailMessage();
                userMessage.setOrgWideEmailAddressId(Label.OrgWideEmailAddressIdContactOB);
                userMessage.setTemplateId(templateId);
                userMessage.saveAsActivity = true;
                /* GDR CRM-1402 Begin - envoi de l'email au contact associé à l'opportunité */
                /*userMessage.setWhatId(oppId);*/
                /* userMessage.setTargetObjectId(mapOpp.get(oppId).Account.PersonContactId);*/
                userMessage.setWhatId(mapOpp.get(oppId).Opportunity.Id);
                userMessage.setTargetObjectId(mapOpp.get(oppId).Contact.Id);
                /* GDR CRM-1402 End */
                mailList.add(userMessage);
            }
            Messaging.sendEmail(mailList);
        } catch (Exception e) {
            e.setMessage(Label.EmailNotSend);
        }
    }
    
    /**
    * @author Ragon François
    * @creation 23/08/2017
    * @description Send an email in the Real Estate process for GB
    */
    public static void sendMailRealEstate(List<Opportunity> opps) {
        List<Opportunity> oppsToSendReceivedFileEmail = new List<Opportunity>();
        List<Opportunity> oppsToSendCaseRefusedEmail = new List<Opportunity>();
        for (Opportunity opp : opps) {
            if (opp.StageName == Label.OpportunityStgNameReceivedByBO) {
                oppsToSendReceivedFileEmail.add(opp);
            } else if (opp.StageName == Label.OpportunityStgNameCaseRefused) {
                oppsToSendCaseRefusedEmail.add(opp);
            }
        }
    }
    
    public static void checkRealizedBy(List<Opportunity> listOpps) {
        Set<Id> usersBBId = new Set<Id>();
        
        for (Opportunity opp : listOpps) {
            String stringId = (String)opp.RealizedBy__c;
            if (stringId != null && (stringId.length() == 15 || stringId.length() == 18)) {
                usersBBId.add(opp.RealizedBy__c);
            }
        }
        Map<Id, User> usersBB = new Map<Id, User>([SELECT isActive FROM User WHERE Id IN :usersBBId]);
        
        for (Opportunity opp : listOpps) {
            User usr = usersBB.get(opp.RealizedBy__c);
            if (usr == null || !usr.isActive) {
                opp.RealizedBy__c = Label.UserIdFrontEnd;
            }
        }
    }
    
    /**
    * @author GASPARD Etienne
    * @creation 05/01/2018
    * @description Get Contact (subscriber) link to Open Opport
    */
    public static void getSubscriberFromOpp(Set<Id> oppsId) {
        //Final Contact IDs to Sync
        Set<Id> contactIdsToSync = new Set<Id>();
        Set<Id> personAccMineur = new Set<Id>();
        
        //Account ID for Opportunities
        List<Account> accsIdOpps = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :oppsId)];
        /* Modifié by Ibrahim Merabti : 25/09/2018 pour le ticket CRM-1000 */ 
        List<OpportunityContactRole> lstOppConRole = [SELECT Contact.IsContactAccountSync__c,ContactId,Contact.Person__c,Contact.TCH_MinorGuest__c,Role,Opportunity.RecordType.DeveloperName,Opportunity.StageName 
                                                        FROM OpportunityContactRole 
                                                        WHERE (Opportunity.RecordType.DeveloperName = 'OBOpportunity' 
                                                               OR Opportunity.RecordType.DeveloperName = 'OBCredit' 
                                                               OR Opportunity.RecordType.DeveloperName = 'OBTracing'
                                                               OR Opportunity.RecordType.DeveloperName = 'OBImmobilier') 
                                                            AND (Contact.RecordType.DeveloperName = 'Subscriber' 
                                                                  OR Contact.RecordType.DeveloperName = 'moralSuscriber')
                                                            AND OpportunityId IN :oppsId];
       
        for (OpportunityContactRole oppCo :lstOppConRole) {  
            if(!oppCo.Contact.IsContactAccountSync__c)
                contactIdsToSync.add(oppCo.ContactId);
            System.debug(' lstOppConRole cont id: '+oppCo.ContactId);
            System.debug(' oppCo.Opportunity.RecordType.DeveloperName: '+oppCo.Opportunity.RecordType.DeveloperName);
            System.debug(' oppCo.Role: '+oppCo.Role);
            System.debug(' oppCo.Contact.TCH_MinorGuest__c: '+oppCo.Contact.TCH_MinorGuest__c);
            if(oppCo.Opportunity.RecordType.DeveloperName=='OBOpportunitys'&&oppCo.Role=='04'&&oppCo.Contact.TCH_MinorGuest__c)
                System.debug('personAccMineur lop: '+oppCo.Contact.Person__c);
            if(oppCo.Opportunity.RecordType.DeveloperName=='OBOpportunity'&&oppCo.Role=='04'&&oppCo.Contact.TCH_MinorGuest__c&&oppCo.Contact.Person__c!=null)
            {
                personAccMineur.add(oppCo.Contact.Person__c);
            }
        }
        
         System.debug('personAccMineur: '+personAccMineur);        
        if(!personAccMineur.isEmpty())
            updateAccMinor(personAccMineur);
        if (!contactIdsToSync.isEmpty()) {
            updateAccountFromContactIds(contactIdsToSync);  
        }
    }
    
    //this methid is used to update prospect minor to client
    public static void updateAccMinor(Set<Id> setIdAccs) { 
        System.debug('updateAccMinor');
        Map<String, map<String, RecordType>> recordTypeMap = UtilsMethods.getRecordTypesBySObject(new List<String> {'Account'});
        List<Account> prospectMinorToClientList=new List<Account>();
        for(Id idAcc:setIdAccs)
        {
            Account prospecMin=new account(id=idAcc);
            prospecMin.type='01';
            prospecMin.RecordTypeId=recordTypeMap.get('Account').get('Person').Id;
            prospectMinorToClientList.add(prospecMin);
        }
       System.debug('prospectMinorToClientList: '+prospectMinorToClientList);   
        update prospectMinorToClientList;
    }
     
     
    /**
    * @author GASPARD Etienne
    * @creation 05/01/2018
    * @description Update account fields using subscriber fields for enrolment opp
    */
    public static void updateAccountFromContactIds(Set<Id> setIdContacts) {
        
        List<Account> accToUpdate = new List<Account>();
        List<Contact> coToUpdate = new List<Contact>();
        Map<String, map<String, RecordType>> recordTypeMap = UtilsMethods.getRecordTypesBySObject(new List<String> {'Contact'});
        Id KYCDataRTiD = recordTypeMap.get('Contact').get('KycData').Id;
        Id souscripteurMoralRTID = (Id) System.Label.ContactRTIdSubscriberMoral;
        List<Account> accMoralToUpdate = new List<Account>();
        List<Contact> coMoralToUpdate = new List<Contact>();
        
        // Contact Physique 
        List<Contact> lstContactPhysique = [SELECT Id, Person__c, FirstName, LastName, Salutation, Birthdate, MobilePhone, Email, MaritalStatus__c, BirthCountry__c, BirthDepartment__c, 
                                            BirthCity__c, MaidenName__c, Nationality__c, USNationality__c, BirthPostalCode__c, AdditionToAddress__c, MailingPostalCode, MailingCountry, 
                                            MailingStreet, DependentChildrenNb__c, OccupationNiv1__c, OccupationNiv3__c, PrimaryResidOccupationType__c, PrimaryResidenceEntryDate__c, 
                                            MailingCity, EmploymentContractEndDate__c, RecordTypeId, EmploymentContractType__c, ActivityBranch__c, EmploymentContractStartDate__c, 
                                            Occupation__c, MonthNetIncome__c, MonthFoncIncome__c, FamilyAllocation__c, HousingAllocation__c, MonthOtherIncomes__c, MonthPaidPension__c, 
                                            MonthExpenses__c, IDCustomerCID__c, CreditInProgressExceptOB__c, IsContactAccountSync__c, Preattribution__c, DistributorNetwork__c, 
                                            EmployeeType__c, GeolifeSegment__c, FiscalCountry__c, DigitalScore__c,OFFirstContactDate__c FROM Contact WHERE (Id IN : setIdContacts) AND (RecordTypeId !=: souscripteurMoralRTID)]; 
        
        for (Contact c : lstContactPhysique) {
            
            // for(Contact c:ca){
            Account currentAcc = new account(id = c.Person__c);
            if(!String.isBlank(c.FirstName)){
                currentAcc.FirstName = c.FirstName;
            }
            if(!String.isBlank(c.LastName)){
                currentAcc.LastName = c.LastName;
            }
            if(!String.isBlank(c.Salutation)){
                currentAcc.Salutation = c.Salutation;
            }
            if(c.BirthDate != null){
                currentAcc.PersonBirthdate = c.BirthDate;
            }
            if(!String.isBlank(c.MobilePhone)){
                currentAcc.PersonMobilePhone = c.MobilePhone;
            }
            if(!String.isBlank(c.Email)){
                currentAcc.PersonEmail = c.Email;
            }
            if(!String.isBlank(c.MaritalStatus__c)){
                currentAcc.MaritalStatus__pc = c.MaritalStatus__c;
            }
            if(!String.isBlank(c.BirthCountry__c)){
                currentAcc.BirthCountry__pc = c.BirthCountry__c;
            }
            if(!String.isBlank(c.BirthCity__c)){
                currentAcc.BirthCity__pc = c.BirthCity__c;
            }
            if(!String.isBlank(c.BirthDepartment__c)){
                currentAcc.BirthDepartment__pc= c.BirthDepartment__c;  
            }
            if(!String.isBlank(c.MaidenName__c)){
                currentAcc.MaidenName__pc = c.MaidenName__c;
            }
            if(!String.isBlank(c.Nationality__c)){
                currentAcc.Nationality__pc = c.Nationality__c;
            }
            if(!String.isBlank(c.USNationality__c)){
                currentAcc.USNationality__pc = c.USNationality__c; 
            }
            if(!String.isBlank(c.BirthPostalCode__c)){
                currentAcc.BirthPostalCode__pc = c.BirthPostalCode__c; 
            }
            if(!String.isBlank(c.FiscalCountry__c)){
                currentAcc.FiscalCountry__c= c.FiscalCountry__c; 
            }
            
            if(!String.isBlank(c.MailingPostalCode)){
                currentAcc.BillingPostalCode = c.MailingPostalCode;
            }
            if(!String.isBlank(c.MailingCountry)){
                currentAcc.BillingCountry = c.MailingCountry;
            }
            
            if(!String.isBlank(c.MailingStreet)){
                currentAcc.BillingStreet = c.MailingStreet;
            }
            
            if(!String.isBlank(c.MailingCity)){
                currentAcc.BillingCity = c.MailingCity;
            }
            if(!String.isBlank(c.AdditionToAddress__c) && !c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL)){
                System.debug('je rentre ici ' + !c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL));
                currentAcc.AdditionToAddress__c = c.AdditionToAddress__c;
            }
            else if (c.AdditionToAddress__c != null && c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL)){
                System.debug('je rentre la ' + c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL));
                currentAcc.AdditionToAddress__c = ' ';
            }
            if(!String.isBlank(c.OccupationNiv1__c)){
                currentAcc.OccupationNiv1__pc = c.OccupationNiv1__c;
            }
            if(!String.isBlank(c.OccupationNiv3__c)){
                currentAcc.OccupationNiv3__pc = c.OccupationNiv3__c;
            }
            
            if(!String.isBlank(c.PrimaryResidOccupationType__c)){
                currentAcc.PrimaryResidOccupationType__pc = c.PrimaryResidOccupationType__c;
            }
            
            if(c.PrimaryResidenceEntryDate__c != null){
                
                currentAcc.PrimaryResidenceEntryDate__pc = c.PrimaryResidenceEntryDate__c;
            }
            if(c.DependentChildrenNb__c != null){
                
                currentAcc.DependentChildrenNb__pc = c.DependentChildrenNb__c;
            }
            if(!String.isBlank(c.Occupation__c)){
                currentAcc.Occupation__pc = c.Occupation__c;
            }
            if(!String.isBlank(c.EmploymentContractType__c) || c.EmploymentContractType__c == '03'){
                currentAcc.EmploymentContractType__pc = c.EmploymentContractType__c;
                currentAcc.EmploymentContractStartDate__pc = null;
            }
            if(!String.isBlank(c.ActivityBranch__c)){
                currentAcc.OccupationArea__c = c.ActivityBranch__c;
            }
            if(c.EmploymentContractStartDate__c != null){
                currentAcc.EmploymentContractStartDate__pc = c.EmploymentContractStartDate__c;
            }
            if (c.EmploymentContractType__c != '01' && c.EmploymentContractType__c != '04' && c.EmploymentContractType__c != '05' && c.EmploymentContractType__c != '08'){
                currentAcc.EmploymentContractEndDate__pc = null;
            }
            if(c.EmploymentContractEndDate__c != null){
                currentAcc.EmploymentContractEndDate__pc = c.EmploymentContractEndDate__c;
            }
            if(c.MonthNetIncome__c != null){
                currentAcc.MonthNetIncome__pc = c.MonthNetIncome__c;
            }
            if(c.MonthFoncIncome__c != null){
                currentAcc.MonthFoncIncome__pc = c.MonthFoncIncome__c;
            }
            if(c.FamilyAllocation__c != null){
                currentAcc.FamilyAllocation__pc = c.FamilyAllocation__c;
            }
            if(c.HousingAllocation__c != null){
                currentAcc.HousingAllocation__pc = c.HousingAllocation__c;
            }
            if(c.MonthOtherIncomes__c != null){
                currentAcc.MonthOtherIncomes__pc = c.MonthOtherIncomes__c;
            }
            if(c.MonthPaidPension__c != null){
                currentAcc.MonthPaidPension__pc = c.MonthPaidPension__c;
            }
            if(c.MonthExpenses__c != null){
                currentAcc.MonthExpenses__pc = c.MonthExpenses__c;
            }
            if(!String.isBlank(c.IDCustomerCID__c)){
                currentAcc.IDCustomerCID__c = c.IDCustomerCID__c;
            }
            
            if(c.FamilyAllocation__c == null){
                currentAcc.FamilyAllocation__pc = 0 ;
            }
            
            if(c.HousingAllocation__c == null){
                currentAcc.HousingAllocation__pc = 0 ;
            }
            
            if(c.FamilyAllocation__c != null && c.HousingAllocation__c != null){
                currentAcc.MonthSocBenefits__pc = c.FamilyAllocation__c + c.HousingAllocation__c;
            }
            
            if(c.FamilyAllocation__c == null && c.HousingAllocation__c == null){
                currentAcc.MonthSocBenefits__pc = 0;
            }
            
            if(c.FamilyAllocation__c != null && c.HousingAllocation__c == null){
                currentAcc.MonthSocBenefits__pc = c.FamilyAllocation__c;
            }
            
            if(c.FamilyAllocation__c == null && c.HousingAllocation__c != null){
                currentAcc.MonthSocBenefits__pc = c.HousingAllocation__c; 
            }
            if(c.CreditInProgressExceptOB__c != null){
                currentAcc.CreditInProgressExceptOB__pc = c.CreditInProgressExceptOB__c;
            }
            if(c.Preattribution__c != null){
                currentAcc.Preattribution__c = c.Preattribution__c;
            }
            if(!String.isBlank(c.DistributorNetwork__c)){
                currentAcc.DistributorNetwork__c = c.DistributorNetwork__c;
            }
            if(!String.isBlank(c.EmployeeType__c)){
                currentAcc.EmployeeType__pc = c.EmployeeType__c;
            }
            if(!String.isBlank(c.GeolifeSegment__c)){
                currentAcc.GeolifeSegment__c = c.GeolifeSegment__c;
            }
            if(c.DigitalScore__c!= null){
                currentAcc.DigitalScore__pc= c.DigitalScore__c;
            }
            if(c.OFFirstContactDate__c!= null){
                currentAcc.OFFirstContactDate__c= c.OFFirstContactDate__c;
            }
            
            
            
            //convertTracingProspect(currentAcc);
            accToUpdate.add(currentAcc);
            c.IsContactAccountSync__c = true;
            coToUpdate.add(c);
        }
        
        // Contact Moral 
        List<Contact> lstContactMoral = [SELECT Id, Person__c, person__r.KYCValidationDate__pc, Name,DistributorNetwork__c,MailingPostalCode,MailingCountry,MailingStreet,MailingCity,
                                         ShopNetworkMesh__c,Interlocuteur__c,RecordTypeId, fonctionInterlocuteur__c,IDCustomerCID__c,SocialReason__c,LegalForm__c,NumSiret__c, 
                                         MailingAddress, AdditionToAddress__c,Email,Turnover__c,exerciceReference__c, agenceCommerciale__c,MainCommercial__c,ActivityBranch__c,
                                         LabelNAFRev2__c,CodeNAFRev2__c, MobilePhone,HomePhone,BusinessPhone__c,FiscalCountry__c,Fax, KYCValidationDate__c FROM Contact WHERE 
                                         (Id IN : setIdContacts) AND (RecordTypeId =: souscripteurMoralRTID )];
                                         
        for (Contact c : lstContactMoral) {
            
            //for(contact c:ca){
            Account currentAcc = new account(id = c.Person__c);
            //currentAcc.name=c.name;       
            if(!String.isBlank(c.DistributorNetwork__c)){
                currentAcc.DistributorNetwork__c = c.DistributorNetwork__c;
            }
            if(!String.isBlank(c.ShopNetworkMesh__c)){
                currentAcc.ShopNetworkMesh__c = c.ShopNetworkMesh__c;
            }
            if(!String.isBlank(c.Interlocuteur__c)){
                currentAcc.Interlocuteur__c = c.Interlocuteur__c;
            }
            if(!String.isBlank(c.fonctionInterlocuteur__c)){
                currentAcc.Finterlocuteur__c= c.fonctionInterlocuteur__c;
            }
            if(!String.isBlank(c.IDCustomerCID__c)){
                currentAcc.IDCustomerCID__c = c.IDCustomerCID__c;
            }
            if(!String.isBlank(c.SocialReason__c)){
                currentAcc.SocialReason__c = c.SocialReason__c;
            }
            if(!String.isBlank(c.LegalForm__c)){
                currentAcc.LegalForm__c = c.LegalForm__c;
            }
            if(!String.isBlank(c.NumSiret__c)){
                currentAcc.NumSiret__c = c.NumSiret__c;
            }
            
            if(!String.isBlank(c.MailingPostalCode)){
                currentAcc.BillingPostalCode = c.MailingPostalCode; 
            }
            
            if(!String.isBlank(c.MailingCountry)){
                currentAcc.BillingCountry = c.MailingCountry;
            }
            
            if(!String.isBlank(c.MailingStreet)){
                currentAcc.BillingStreet = c.MailingStreet;
            }
            
            if(!String.isBlank(c.MailingCity)){
                currentAcc.BillingCity = c.MailingCity;
            }
            if(!String.isBlank(c.AdditionToAddress__c) && !c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL)){
                System.debug('je rentre ici ' + !c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL));
                currentAcc.AdditionToAddress__c = c.AdditionToAddress__c;
            }
            else if (c.AdditionToAddress__c != null && c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL)){
                System.debug('je rentre la ' + c.AdditionToAddress__c.contains(Label.TAGAttributNULLBYSL));
                currentAcc.AdditionToAddress__c = ' ';
            }
            if(!String.isBlank(c.Email)){
                currentAcc.Email__c = c.Email;
            }
            if(c.Turnover__c != null){
                currentAcc.Turnover__c = c.Turnover__c;
            }
            if(c.exerciceReference__c!= null){
                currentAcc.exerciceReference__c = c.exerciceReference__c;
            }
            if(!String.isBlank(c.agenceCommerciale__c)){
                currentAcc.agenceCommerciale__c = c.agenceCommerciale__c;
            }
            if(!String.isBlank(c.MainCommercial__c)){
                currentAcc.Commercialprincipal__c = c.MainCommercial__c;
            }
            if(!String.isBlank(c.ActivityBranch__c)){
                currentAcc.OccupationArea__c= c.ActivityBranch__c;
            }
            if(!String.isBlank(c.LabelNAFRev2__c)){
                currentAcc.LabelNAFRev2__c = c.LabelNAFRev2__c;
            }
            if(!String.isBlank(c.CodeNAFRev2__c)){
                currentAcc.CodeNAFRev2__c = c.CodeNAFRev2__c;
            }
            if(!String.isBlank(c.MobilePhone)){
                currentAcc.MobilePhone__c = c.MobilePhone;
            }
            if(!String.isBlank(c.HomePhone)){
                currentAcc.HomePhone__c = c.HomePhone;
            }
            if(!String.isBlank(c.BusinessPhone__c)){
                currentAcc.BusinessPhone__c = c.BusinessPhone__c;
            }
            if(!String.isBlank(c.FiscalCountry__c)){
                currentAcc.FiscalCountry__c = c.FiscalCountry__c;
            }
            if(!String.isBlank(c.Fax)){
                currentAcc.Fax= c.Fax;
            }
            
            if(c.person__r.KYCValidationDate__pc != null){
                currentAcc.KYCValidationDate__pc = c.person__r.KYCValidationDate__pc;
            }
            
            accMoralToUpdate.add(currentAcc);
            c.IsContactAccountSync__c = true;
            coMoralToUpdate.add(c);
        } 
        
        if (!accToUpdate.isEmpty() || !accMoralToUpdate.isEmpty()) {
            
            List<User> userB01=[select name,id from user where id=:UserInfo.getUserId() and Profile.Name='BackOffice Profil  1'];
            if(!userB01.isEmpty())
            {
                KYC_PjOK_B01GrantSaveRecords.updateAccountandContact(accToUpdate,coToUpdate,accMoralToUpdate,coMoralToUpdate);
            }
            else
            {
                PAD.ApexForcedBypass.add('execCtcBefUpd'); PAD.ApexForcedBypass.add('execAccBefUpd'); PAD.ApexForcedBypass.add('execAccAftUpd');
                if (!accToUpdate.isEmpty()) {
                    update accToUpdate;
                    update coToUpdate;
                }
                if (!accMoralToUpdate.isEmpty()) {    
                    update accMoralToUpdate;
                    update coMoralToUpdate;
                }    
                PAD.ApexForcedBypass.remove('execCtcBefUpd'); PAD.ApexForcedBypass.remove('execAccBefUpd'); PAD.ApexForcedBypass.remove('execAccAftUpd');
            }
            
        }

    }
    
    public static void sendMailOppCred(Set<Id> oppsCred) {
        List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
        Map<Id, List<OpportunityContactRole>> mapOpp = new Map<Id, List<OpportunityContactRole>>();
        List<OpportunityContactRole> tempListOCR;
        
        //Map Opportunity -> List Opport Contact Role // Commenter par YRU à la demande d'Alexis & De ROUZE, lié aux US crédits goteborg prevu pour 2019
        List<OpportunityContactRole> lstOppConRole1 = [SELECT Id, OpportunityId, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.MonthNetIncome__c, 
                                                       Contact.EmploymentContractType__c FROM OpportunityContactRole WHERE OpportunityId IN : oppsCred];
        for (OpportunityContactRole opcr1 : lstOppConRole1) {
            if (!mapOpp.containsKey(opcr1.OpportunityId)) {
                tempListOCR = new List<OpportunityContactRole>();
                tempListOCR.add(opcr1);
                mapOpp.put(opcr1.OpportunityId, tempListOCR);
            } else (mapOpp.get(opcr1.OpportunityId)).add(opcr1);
        }
        
        //Envoi d'un mail au commercial en charge de l'opport crédit
        /*for (Opportunity  myOpport : [SELECT LastModifiedById, StageName, FundingSubject__c, CreditAmount__c, OffersRate__c FROM Opportunity WHERE RecordType.DeveloperName = 'OBCredit'
        AND Id IN : mapOpp.keySet()]) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(myOpport.LastModifiedById);
        mail.setOrgWideEmailAddressId(Label.OrgWideEmailAddressIdContactOB);
        mail.setWhatId(myOpport.Id);
        mail.setTemplateId(Label.EmailTemplateIdOperatorCredit);
        mail.saveAsActivity = false;
        lstMails.add(mail);
        }
        Messaging.sendEmail(lstMails);*/
    }
    
    /**
    * @author Yanis AMOKRANE
    * @creation 29/08/2017
    * @lastEdit François Ragon on 16/10/2017
    * @description Close cases related to given opportunities depending on some rules
    */
    /*public static void closeRelatedCss(List<Opportunity> listOpps, Map<Id, Opportunity> oldOpps) {
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>(listOpps);
        List<Case> caseList = [SELECT Status, Subtype__c, RecordType.DeveloperName, ParentOppy__c FROM Case WHERE ParentOppy__c IN:listOpps];
        List<Case> caseToUpdate = new List<Case>();
        for (Case c : caseList) {
            if (c.Status != '03' && ((c.RecordType.DeveloperName == 'OBPJBDFControl' && oldOpps.get(c.ParentOppy__c).StageName == Label.OpportunityStgNameBankControl) || 
                                     (c.RecordType.DeveloperName == 'OBMarketingRequest' && oppsMap.get(c.ParentOppy__c).DistributionChannel__c == '01' && 
                                     (c.Subtype__c == '153' || c.Subtype__c == '154' || c.Subtype__c == '155' || c.Subtype__c == '156')))) {
                                         
                c.Status = '03';
                c.Comments255__c = c.RecordType.DeveloperName == 'OBPJBDFControl' ? Label.CasePJBDFAutoCloseMsg : c.Comments255__c;
                caseToUpdate.add(c);
            }
        }
        
        PAD.ApexForcedBypass.add('execCsBefUpd'); PAD.ApexForcedBypass.add('execCsAftUpd');
        update caseToUpdate;
        PAD.ApexForcedBypass.remove('execCsBefUpd'); PAD.ApexForcedBypass.remove('execCsAftUpd');
    }*/
    
    /**
    * @author Gaspard Etienne
    * @creation 01/12/2017
    * @description Check if the Retractation Date is correct to change the StageName to retractation
    */
    public static void updateOppStageNRetracDate(List<Opportunity> oppsToRetract) {
        Boolean b1, b2, b3, b4;
        List<Holiday> holidays = new List <Holiday>([SELECT Id, ActivityDate FROM Holiday]);
        for (Opportunity opp : oppsToRetract) {
            if (opp.RetractationDate__c == null || opp.RetractationDate__c < opp.SignatureDate__c || opp.RetractationDate__c > opp.SignatureDate__c.addDays(17)) {
                opp.addError(Label.OppCreditErrorRetractationDate);
            } else {
                b1 = AP08OpportunityUtils.checkifItisOffDay(opp.RetractationDate__c.addDays(-1), holidays);
                b2 = AP08OpportunityUtils.checkifItisOffDay(opp.RetractationDate__c.addDays(-2), holidays);
                b3 = AP08OpportunityUtils.checkifItisOffDay(opp.RetractationDate__c.addDays(-3), holidays);
                if ((opp.RetractationDate__c == opp.SignatureDate__c.addDays(15) && !b1) || (opp.RetractationDate__c == opp.SignatureDate__c.addDays(16) && (!b1 || !b2)) || 
                    (opp.RetractationDate__c == opp.SignatureDate__c.addDays(17) && (!b1 || !b2 || !b3))) {
                        opp.addError(Label.OppCreditErrorRetractationDate);
                    }
            }
        }
    }
    
    public static boolean checkifItisOffDay(Date retracDate, List<Holiday> holidays) {
        Date weekStart = retracDate.toStartofWeek().addDays(-1);
        for (Holiday hDay : holidays) {
            //if date fall in holiday then return true.
            if (retracDate.daysBetween(hDay.ActivityDate) == 0) {
                return true;
            }
        }
        //if date fall in weekend return true
        if (weekStart.daysBetween(retracDate) == 7 || weekStart.daysBetween(retracDate) == 6) {
            return true;
        } else {
            return false;
        }
    }
    //AKA: CRM 1000 cocher TCH_ClientGroupama pour les comptes liés à l'opportunité de tracage.
    /* private static List<Id> RetrieveClientfromOpp(Opportunity opp) {
    List<Id> conId = new List<Id>();
    List<OpportunityContactRole> ocr = [SELECT ID, contactId from opportunityContactRole WHERE opportunityId =:opp.Id];
    if(ocr.size()>0 ){
    conId.add(ocr[0].ContactId);
    if(ocr.size()==2){
    conId.add(ocr[1].ContactId);
    } 
    }
    List<Id> acc = new List <Id>();
    List <contact> con = [SELECT Id, Person__c from Contact WHERE Id IN :conId];
    for(Contact c:con){
    acc.add(c.Person__c);
    }
    return acc;
    }*/
        
        /* Added by Ibrahim Merabti to convert physical prospects to clients in the case of Tracing opportunities */ 
        /*
    private static void convertTracingProspect(Account acc) {
    acc.ClientDataUpdate__c = true;  
    acc.NoOrangeEmail__pc = true;
    acc.NoOrangeSMS__pc = true;
    acc.NoPartnerEmail__pc = true;
    acc.NoPartnerSMS__pc = true;
    acc.recordTypeID = Label.AccountRTIdClient;
    acc.Type = '01';
    
    }*/
    
     /**
    * @author Fatima AZERZOU
    * @creation 24/04/2020
    * @description Update Account Data Telco and Order Telco
    */
    public static void UpdateTecloOptinAccount(Set < Id > oppsId) {

        //Account ID for Opportunities
        List < Account > accToUpdate = [SELECT Id, OptInDataTelco__c, OptInOrderTelco__c FROM Account WHERE Id IN(SELECT AccountId FROM Opportunity WHERE Id IN: oppsId)];

        if (!accToUpdate.isEmpty()) {
            for (Account currentAcc: accToUpdate) {
                currentAcc.OptInDataTelco__c = true;
                currentAcc.OptInOrderTelco__c = true;
                currentAcc.OptinPreattTelco__c = true;
            }
            PAD.ApexForcedBypass.add('execAccBefUpd');
            PAD.ApexForcedBypass.add('execAccAftUpd');
            update accToUpdate;
            PAD.ApexForcedBypass.remove('execAccBefUpd');
            PAD.ApexForcedBypass.remove('execAccAftUpd');

        }
    }
    
     /**
    * @author Nabil KHCHAF
    * @creation 09/07/2020
    * @description Update Account Telco Preat
    */
    public static void UpdateTecloOptinPreatAccount (Set < Id > oppsId) {
        //Account ID for Opportunities
        List < Account > accToUpdate = [SELECT Id, OptinPreattTelco__c FROM Account WHERE Id IN(SELECT AccountId FROM Opportunity WHERE Id IN: oppsId)];

        if (!accToUpdate.isEmpty()) {
            for (Account currentAcc: accToUpdate) {
                currentAcc.OptinPreattTelco__c = true;
            }
            PAD.ApexForcedBypass.add('execAccBefUpd');
            PAD.ApexForcedBypass.add('execAccAftUpd');
            update accToUpdate;
            PAD.ApexForcedBypass.remove('execAccBefUpd');
            PAD.ApexForcedBypass.remove('execAccAftUpd');

        }
    }
    
    @future
    public static void updateTechDesirio(List<Id> opportIdsToUpdateDesirio) {
        List<Opportunity> oppsToUpdateDesirio = [select Id from Opportunity where Id = :opportIdsToUpdateDesirio];
        for (Opportunity opp : oppsToUpdateDesirio) {
            opp.TCH_PTD__c = true;
        }
        update oppsToUpdateDesirio;
    }
    
    
    public static String translateOppStageName(String picklistValue) {
        //Useful for translation
        Schema.DescribeFieldResult fieldSchema = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldSchema.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.getValue() == picklistValue) {
                return entry.getLabel();
            }
        }
        //If not found, just don't translate
        return picklistValue;
    }
    
     public static String translateOppCommitmentRefusalReason(String picklistValue) {
        //Useful for translation
        Schema.DescribeFieldResult fieldSchema = Opportunity.CommitmentRefusalReason__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldSchema.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.getValue() == picklistValue) {
                return entry.getLabel();
            }
        }
        //If not found, just don't translate
        return picklistValue;
    }

     public static String translateOppDerogation(String picklistValue) {
        //Useful for translation
        Schema.DescribeFieldResult fieldSchema = Opportunity.Derogation__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldSchema.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.getValue() == picklistValue) {
                return entry.getLabel();
            }
        }
        //If not found, just don't translate
        return picklistValue;
    }
    
    public static String translateOppRejectedReason(String picklistValue) {
        //Useful for translation
        Schema.DescribeFieldResult fieldSchema = Opportunity.RejectReason__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldSchema.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.getValue() == picklistValue) {
                return entry.getLabel();
            }
        }
        //If not found, just don't translate
        return picklistValue;
    }
    
    
    /* CRM-2467 - Début */
    /* public static void CloseCaseOppCred(Set<Id> oppsCredClose) { 
      List<Opportunity> lstOppField = [SELECT Id, toLabel(StageName),toLabel(CommitmentRefusalReason__c),toLabel(Derogation__c),toLabel(RejectReason__c) FROM Opportunity WHERE Id IN : oppsCredClose];
      List<Case> lstCaseField = [SELECT Id,status,RecordType.developerName,ParentOppy__c,LoanDecision__c,ReasonForDecision__c FROM Case WHERE (ParentOppy__r.Id IN : oppsCredClose) and (RecordType.developerName = 'OBCreditRequest' and status!='03')];
      List<Case> CaseToUpdate= new List<Case>();
       system.debug('###YRU:'+lstOppField);
       system.debug('###YRU1:'+lstCaseField);
      
        for(Case c:lstCaseField){
           for(Opportunity opp:lstOppField){
            c.LoanDecision__c=opp.StageName;
            c.status='03';
            if(opp.CommitmentRefusalReason__c!=null){
             c.ReasonForDecision__c=opp.CommitmentRefusalReason__c; 
            }
             else if(opp.Derogation__c!=null){
             c.ReasonForDecision__c=opp.Derogation__c; 
            }
             else if(opp.RejectReason__c !=null){
             c.ReasonForDecision__c=opp.RejectReason__c ; 
            }
            CaseToUpdate.add(c);
           } 
            if (!CaseToUpdate.isEmpty()) 
            update CaseToUpdate;
        }   
    } */
    public static void CloseCaseOppCred(map<Id,Opportunity> oppsCredCloseMap,map<String,String> ApiToLabel) { 
      List<Case> lstCaseField = [SELECT Id,status,RecordType.developerName,ParentOppy__c,ParentOppy__r.Id,LoanDecision__c,ReasonForDecision__c FROM Case WHERE (ParentOppy__r.Id IN : oppsCredCloseMap.keySet()) and (RecordType.developerName = 'OBCreditRequest' and status!='03')];
      List<Case> CaseToUpdate= new List<Case>();
      
       system.debug('###YRU1:'+lstCaseField);
      
        for(Case c:lstCaseField){
            c.LoanDecision__c=ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).StageName);
            c.status='03';
            if(oppsCredCloseMap.get(c.ParentOppy__r.Id).CommitmentRefusalReason__c!=null){
                System.debug('CommitmentRefusalReason__c: '+oppsCredCloseMap.get(c.ParentOppy__r.Id).CommitmentRefusalReason__c);
                c.ReasonForDecision__c=ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).CommitmentRefusalReason__c); 
                System.debug('Label CommitmentRefusalReason__c: '+ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).CommitmentRefusalReason__c));
            }
             else if(oppsCredCloseMap.get(c.ParentOppy__r.Id).Derogation__c!=null){
                 System.debug('Derogation__c: '+oppsCredCloseMap.get(c.ParentOppy__r.Id).Derogation__c);    
                 c.ReasonForDecision__c=ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).Derogation__c); 
                 System.debug('Label Derogation__c: '+ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).Derogation__c));
            }
             else if(oppsCredCloseMap.get(c.ParentOppy__r.Id).RejectReason__c!=null){
                 System.debug('RejectReason__c: '+oppsCredCloseMap.get(c.ParentOppy__r.Id).RejectReason__c); 
                c.ReasonForDecision__c=ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).RejectReason__c); 
                 System.debug('Label RejectReason__c: '+ApiToLabel.get(oppsCredCloseMap.get(c.ParentOppy__r.Id).RejectReason__c)); 
            }
            CaseToUpdate.add(c);       
        }
        if (!CaseToUpdate.isEmpty()) 
            update CaseToUpdate;    
    }
    /* CRM-2467 - Fin */
    
    public static void updateCaseOwnerAccountOpen(Map<Id,opportunity> oppsAccountOpen) {
        List<Case> caseList=new List<Case>();
        List<Group> groupList=new List<Group>(); 
        /* CRM-2432 - Début */
        List<Case> caseToUpdateList=new List<Case>();
         
        /*caseList=[select id,ownerid,ParentOppy__c from case where RecordType.DeveloperName = 'OBRequest' 
                  and ParentOppy__c in:oppsAccountOpen.keyset() and status!='03'];*/
        caseList=[SELECT id,ownerid,ParentOppy__c 
                FROM case 
                WHERE RecordType.DeveloperName = 'OBRequest' 
                    AND ParentOppy__c in:oppsAccountOpen.keyset()
                    AND isClosed = false];
        /* CRM-2432 - Fin*/
        groupList=[SELECT Id,Name, Type FROM Group WHERE Type = 'Queue' AND (Name = 'Domiciliation Bancaire' 
                    OR Name = 'Domiciliation Bancaire en attente')]; 
        System.debug('caseList: '+caseList) ;
        System.debug('groupList: '+groupList) ;
        
        ID idBankingDomiciliation;
        ID idBankingDomiciliationTemp;
        for(Group g:groupList) {
            if(g.Name=='Domiciliation Bancaire')
                idBankingDomiciliation=g.id;
            
            if(g.Name=='Domiciliation Bancaire en attente')
                idBankingDomiciliationTemp=g.id;
        }
        
        System.debug('idBankingDomiciliation: '+idBankingDomiciliation) ;
        System.debug('idBankingDomiciliationTemp: '+idBankingDomiciliationTemp) ;
        
        for(Case c:caseList) {
            if(c.ownerid==idBankingDomiciliationTemp) {
                c.ownerid=idBankingDomiciliation;
                /* CRM-2432 - Début */
                caseToUpdateList.add(c);
                /* CRM-2432 - Fin */
        }
        
    }
    
        /* CRM-2432 - Début */
        //update caseList;
        //System.debug('caseList: '+caseList) ;
        update caseToUpdateList;
        System.debug('caseToUpdateList: ' + caseToUpdateList) ;
        /* CRM-2432 - Fin */
    }
    
     
    public static void closeCaseOppSansSuiteRefuse(Map<Id,opportunity> oppSansSuiteRefuse) { 
      /*List<Case> lstCaseField = new List<Case>();
       
        // lstCaseField =[SELECT Id,status,RecordType.developerName,ParentOppy__c,LoanDecision__c,ReasonForDecision__c FROM Case WHERE ParentOppy__c in:oppSansSuiteRefuse.keyset()];
        lstCaseField =[SELECT Id, status, RecordType.developerName, ParentOppy__c, LoanDecision__c, ReasonForDecision__c 
                    FROM Case 
                    WHERE ParentOppy__c in:oppSansSuiteRefuse.keyset()
                        AND isClosed = false];
       
      
        for(Case c:lstCaseField){
            c.LoanDecision__c=oppSansSuiteRefuse.get(c.ParentOppy__c).StageName;
            c.status='03';
            if(oppSansSuiteRefuse.get(c.ParentOppy__c).DeniedOpportunityReason__c!=null){
             c.ReasonForDecision__c=oppSansSuiteRefuse.get(c.ParentOppy__c).DeniedOpportunityReason__c; 
            } else if(oppSansSuiteRefuse.get(c.ParentOppy__c).RejectReason__c !=null){
             c.ReasonForDecision__c=oppSansSuiteRefuse.get(c.ParentOppy__c).RejectReason__c ; 
            }
        }
         update lstCaseField;   
    */
    }
    
    @InvocableMethod(label = 'get Scor de fraude' description = 'Call Isoft WS to get Score de fraude' )
    public static void getScoreFraudeFromIsoft(List<Opportunity> opps) {
      
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : opps)
        {
            oppIds.add(opp.Id);
        }
        callIsoftTogetScore(oppIds);
  
    }
    
    
    @Future(callout = true)
    public static void callIsoftTogetScore(Set<Id> oppsId) {
        List<Opportunity> opps = [SELECT Id, FraudScore__c, FraudRisk__c, StageName, DeniedOpportunityReason__c FROM Opportunity WHERE  Id in :oppsId];
        WS08_ObjectRacineResponse result = null;
        WS08_ScoreFraudeWebservice requester = new WS08_ScoreFraudeWebservice();
        for(Opportunity opp : opps )
        {
            result = requester.scoreFraudePOST(opp.Id);


            opp.FraudRisk__c = (Result.Racine.return_c.p.DA_EVENT.result).leftpad(2,'0');
            opp.fraudScore__c = Integer.valueOf(Result.Racine.return_c.p.DA_EVENT.score);
            
            // Refus de l'opportunité si le score de fraude est 02
            if(opp.FraudRisk__c == '02') {


                opp.StageName ='10';
                opp.DeniedOpportunityReason__c = '03'; 
            }
        
        }   
    
     update opps;
    }
}