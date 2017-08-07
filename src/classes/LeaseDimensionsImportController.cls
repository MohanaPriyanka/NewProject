/**
 * Created By: Peter Yao
 * Description:  Creates Transaction Applications from a Lease Dimensions daily or monthly payment 
 *               file saved as a CSV
 *               Assumes 16 columns, from Portfolio through Comments
 * Tested by: LeaseDimensionsImportControllerTest
 **/

public without sharing class LeaseDimensionsImportController {
    public Document document {
        get {
            if (document == null)
                document = new Document();
            return document;
        }
        set;
    }
    public String filename {get;set;}
    public String lastDocProcessed {get;set;}
    transient List<Loan__c> loansFound;
    transient Set<String> loanNumbers;
    transient List<ReportLine> reportLines;
    transient Map<String, Loan__c> loanMap;
    public static Map<String, String> descriptionMap =
        new Map<String, String>{'IBL PMT - INTEREST' => 'Interest',
                                'IBL PRN PAYDOWN' => 'Principal',
                                'WRITE DOWN ASST INVN' => 'Principal',
                                'PAYMENT OTHER CHARGE' => 'Interest',
                                'IBL INT CR' => 'Interest',
                                'IBL INT CR REV' => 'Interest',
                                'IBL PRN PAYDOWN REV' => 'Principal',
                                'IBL PMT REV - INT' => 'Interest',
                                'IBL PMT - PRINCIPAL' => 'Principal',
                                'IBL PRN WRITE-DOWN' => 'Principal',
                                'IBL PMT REV - PRN' => 'Principal',
                                'PMT REV OTHER CHARGE' => 'Interest',
                                'IBL PRN WRITE-DN REV' => 'Principal'};

    public LeaseDimensionsImportController() {
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        lastDocProcessed = sysProp.Last_Lease_Dimensions_File_Processed__c;
    }

    public void processCSV() {
        loadCSV();
        generateTAs();
        Logger.flushLogs();
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        sysProp.Last_Lease_Dimensions_File_Processed__c = filename;
        update sysProp;
    }

    private void loadCSV() {
        CSVReader csvReader = new CSVReader(document.body.toString());
        String[] line;
        ReportLine rl;
        loanNumbers = new Set<String>();
        reportLines = new List<ReportLine>();
        while ((line = csvReader.readLine()) != null) {
            if (!isEmpty(line) &&
                !line[0].contains('Portfolio')) {
                try {
                    rl = new ReportLine(line);
                    reportLines.add(rl);
                    loanNumbers.add(rl.loanNumber);
                } catch (LDImportException ldie) {
                    Logger.logLater('LeaseDimensionsImportController', 'loadCSV', ldie.getMessage());
                }
            }
        }
        
        loanMap = new Map<String, Loan__c>();
        for (Loan__c loan : [SELECT Id, Loan_Number__c,
                             (SELECT Id, Period__c, Payment_Due_Date2__c
                              FROM Loan_Payments__r
                              WHERE Period__c <> null
                              ORDER BY Period__c)
                             FROM Loan__c
                             WHERE Loan_Number__c IN :loanNumbers]) {
            loanMap.put(loan.Loan_Number__c, loan);
        }
    }

    private void generateTAs() {
        List<Transaction_Application__c> taList = new List<Transaction_Application__c>();
        Transaction_Application__c ta;
        Loan__c loan;
        for (ReportLine rl : reportLines) {
            try {
                loan = loanMap.get(rl.loanNumber);
                if (loan != null) {
                    taList.add(rl.getTA(loan));
                }
            } catch (LDImportException ldie) {
                Logger.logLater('LeaseDimensionsImportController', 'loadCSV', ldie.getMessage());
            }
        }
        Logger.logLater('LeaseDimensionsImportController', 'loadCSV', 
                        'Inserting ' + taList.size() + ' transaction applications from ' + filename);
        insert taList;
    }

    private class ReportLine {
        String portfolio;
        String company;
        String region;
        String office;
        String account;
        String loanNumber;
        String customerName;
        Date processDate;
        Date paymentEffectiveDate;
        Date invoiceDueDate;
        String transactionDescription;
        String invoiceNumber;
        String checkNumber;
        String cashCode;
        Decimal amount;
        String reversalReason;
        String comments;
        
        private ReportLine(String[] inputLine) {
            if (inputLine.size() != 16 ||
                // Excel saves non-printing characters when saving to csv, so use contains instead of equals
                inputLine[0].contains('Portfolio') ||
                inputLine[4].equals('')) {
                throw new LDImportException('Not processing this line: ' + inputLine);
            }
            portfolio = inputLine[0];
            company = inputLine[1];
            region = inputLine[2];
            office = inputLine[3];
            account = inputLine[4];
            if (account.trim().startsWith('BW')) {
                loanNumber = account.trim();
            } else {
                loanNumber = 'BW' + account.trim().leftPad(7).replace(' ','0');
            }
            customerName = inputLine[5];
            processDate = Date.parse(inputLine[6].trim());
            if (!String.isBlank(inputLine[7])) {
                paymentEffectiveDate = Date.parse(inputLine[7].trim());
            }
            if (!String.isBlank(inputLine[8])) {
                invoiceDueDate = Date.parse(inputLine[8].trim());
            }
            transactionDescription = inputLine[9];
            invoiceNumber = inputLine[10];
            checkNumber = inputLine[11];
            cashCode = inputLine[12];
            amount = parse(inputLine[13]);
            reversalReason = inputLine[14];
            comments = inputLine[15];
        }

        private Decimal parse(String parsed) {
            if (parsed.contains('(') || parsed.contains(')')) {
                parsed = parsed.replaceAll('[(), ]', '');
                return Decimal.valueOf(parsed) * -1;
            } else {
                parsed = parsed.replaceAll('[, ]', '');
                return Decimal.valueOf(parsed);
            }
        }        

        public Transaction_Application__c getTA(Loan__c loan) {
            Transaction_Application__c ta =
                new Transaction_Application__c(Process_Date__c = processDate,
                                               Effective_Date__c = paymentEffectiveDate,
                                               Description__c = transactionDescription,
                                               Invoice_Number__c = invoiceNumber,
                                               Invoice_Due_Date__c = invoiceDueDate,
                                               Check_Number__c = checkNumber,
                                               Cash_Code__c = cashCode,
                                               Comments__c = (String.isBlank(reversalReason)?'':(reversalReason+'\n')) + comments);
            for (Loan_Payment__c lp : loan.Loan_Payments__r) {
                Date applyDate;
                if (invoiceDueDate != null) {
                    applyDate = invoiceDueDate;
                } else if (paymentEffectiveDate != null) {
                    applyDate = paymentEffectiveDate;
                } else {
                    applyDate = processDate;
                }
                if (LoanServicer.appliesTo(applyDate, lp)) {
                    ta.Loan_Payment__c = lp.Id;
                    break;
                }
            }
            if (ta.Loan_Payment__c == null) {
                throw new LDImportException('Could not find a loan payment to relate to. ' +
                                            'Loan: ' + account + ' Invoice Due Date: ' + invoiceDueDate);
            }
            String principalOrInterest;
            if ((principalOrInterest = descriptionMap.get(transactionDescription)) == null) {
                throw new LDImportException('Unknown transaction description found: ' + transactionDescription);
            } else if (principalOrInterest.equals('Principal')) {
                ta.Principal_Applied__c = amount;
            } else {
                ta.Interest_Applied__c = amount;
            }
            if (transactionDescription.equals('IBL PRN WRITE-DN REV') ||
                transactionDescription.equals('IBL PRN WRITE-DOWN') ||
                transactionDescription.equals('WRITE DOWN ASST INVN')) {
                if (comments.toUpperCase().contains('CUSTOMER')) {
                    ta.Principal_Paydown_Reason__c = 'Customer';
                } else {
                    ta.Principal_Paydown_Reason__c = 'IBLS';
                }
            }
            return ta;
        }
    }
    
    public boolean isEmpty(List<String> strings) {
        for (String s : strings) {
            if (!String.isEmpty(s.trim())) {
                return false;
            }
        }
        return true;
    }
    
    public class LDImportException extends Exception {}

}