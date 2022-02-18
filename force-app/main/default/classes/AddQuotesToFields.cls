/**
 * Copyright (c) 2020 CapTech Consulting
 * @File Name          : AddQuotesToFields.cls
 * @Description        : Converts a list of records to CSV and uploaded to Files
 * @Author             : Ragan Walker
 * @Last Modified By   : araganwalker@gmail.com
 * @Last Modified On   : 05/15/2020
 * @License            : LICENSE: https://github.com/captechconsulting/lightning-flow-utils/blob/master/LICENSE 
 * @Modification Log   : 
 * Ver      Date            Author      		        Modification
 * 1.0      05/15/2020      araganwalker@gmail.com      Initial release
**/

global without sharing class AddQuotesToFields {
    global class Input {
        @InvocableVariable(description='Collection of records to transform')
        global List<String> fieldCollection;

        @InvocableVariable(description='Comma separated string of records to transform')
        global String fieldString;

        @InvocableVariable(description='Valid inputs are SINGLE for single quotes or DOUBLE for double quotes; Default value is SINGLE.')
        global String quoteType;
    }

    global class Output {
        @InvocableVariable(description='Collection of records transformed with quotes')
        global List<String> fieldCollection;

        @InvocableVariable(description='Comma separated string of records transformed with quotes')
        global String fieldString;
    }

    @InvocableMethod(description='Add qoutes to each element in a collection')
    global static List<Output> addQuotesToFields(List<Input> inputs) {
        List<Output> outputs = new List<Output>{};
        for (Input input: inputs) {
            if (input.fieldString != null && input.fieldString.length() > 0) {
                input.fieldCollection = input.fieldString.split(',');
            }
            if (input.quoteType == null) {
                input.quoteType = 'SINGLE';
            }
            List<String> transformed = new List<String>{};
            for (String field: input.fieldCollection) {
                if (input.quoteType == 'DOUBLE') {
                    field = '"' + field + '"';
                } else {
                    field = '\'' + field.replace('\'', '\\\'') + '\'';
                }
                transformed.add(field);
            }
            Output output = new Output();
            output.fieldCollection = transformed;
            output.fieldString = String.join(transformed, ',');
            outputs.add(output);
        }
        return outputs;
    }
}