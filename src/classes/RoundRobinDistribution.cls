global class RoundRobinDistribution {
	
	webService static void loadDistributionButton(String objType, Id rrqId){
		loadDistribution(objType, rrqId);		
	}
	
	webService static void loadDistributionAllButton(String objType){
		loadDistribution(objType, null);		
	}

	public static void loadDistribution(String objType, Id rrqId){
		//RRqAssignment
		Map <Id, List <SOBject>> qMap = new Map <Id, List <SObject>>();
		String query = 'SELECT Weight__c, Member__c, Member__r.name, ' + RoundRobinUtils.getQueueObjName(objType)
							+ ' FROM  ' + RoundRobinUtils.getQueueMemberAssignmentObjName(objType)
							+ ' WHERE Weight__c > 0 ';
		
		if(rrqId != null){
			query += ' AND ' + RoundRobinUtils.getQueueObjName(objType) + ' = :rrqId ';
		}
		query += ' ORDER BY ' + RoundRobinUtils.getQueueObjName(objType) + ', Weight__c DESC ';
		
		Set <Id> qIds = new set <Id>();
		
		for(SObject qma : Database.query(query)){
			Id qId = (Id)qma.get(RoundRobinUtils.getQueueObjName(objType));
			qIds.add(qId);
			
			//rrqMemberAssignment
			List <SObject> qmas = new List <SObject>();
			if(qMap.containsKey(qId)){
				qmas = qMap.get(qId);	
			}
			qmas.add(qma);
			qMap.put(qId, qmas);
			system.debug('### ' + (String)qma.getSObject('Member__r').get('Name'));
		}
		
		// the RR_Queue_Member_Assignment__c is already assigned to an existing RR Queue definition.
		// so no maintenance needed there
		// This will determine how to load the data on the queue members
		
		List <SObject> qMembersAll = new List <SObject>();
		for(Id qId : qMap.keyset()){
			List <SObject> qMembers = buildQueueMembers (objType, qId, qMap.get(qId));
			qMembersAll.addAll(qMembers);
		}
		
		Set<Id> qMapKeys = qMap.keySet();
		String deleteQuery = 'SELECT Id FROM ' + RoundRobinUtils.getQueueMemberObjName(objType)
							+' WHERE ' + RoundRobinUtils.getQueueObjName(objType) + ' IN :qMapKeys';
		List <SObject> qMembersToDelete = Database.query(deleteQuery);
		                                                        
		if(!qMembersToDelete.isEmpty()){
			delete qMembersToDelete;
		}
		
		if(!qMembersAll.isEmpty()){
			insert qMembersAll;
		}
		
		List <SObject> qsToUpdate = new List <SObject>();
		
		String updateQuery = 'SELECT Id,Member_Assignments_Last_Executed__c'
							+' FROM ' + RoundRobinUtils.getQueueObjName(objType)
							+' WHERE Id IN :qIds';
		for(SObject q : Database.query(updateQuery)){
			q.put('Member_Assignments_Last_Executed__c',system.now());
			qsToUpdate.add(q);
		}		
		update qsToUpdate;
	}
	
	public static List <SObject> buildQueueMembers (String objType, Id qId, List <SObject> assignments){
		Integer loopCount = Integer.valueOf((Decimal)assignments[0].get('Weight__c'));
		Integer position = 0;
		
		List <SObject> qMembers = new List <SObject>();
		
		// loop through as many times as the first weight since that will always be first in the list
		for (Integer i = 1; i < loopCount + 1; i++) {
    		for(SObject assignment : assignments){
    			Integer assignmentWeight = Integer.valueOf((Decimal)assignment.get('Weight__c'));
    			if(assignmentWeight >= i){
    				String memberName = (String)assignment.getSObject('Member__r').get('Name');
    				system.debug('###MemberName: ' + memberName);
    				position ++;
    				SObject qMember = Schema.getGlobalDescribe().get(RoundRobinUtils.getQueueMemberObjName(objType)).newSObject();
    				qMember.put('Position__c',position);
					qMember.put('Member__c',(Id)assignment.get('Member__c'));    				
    				qMember.put(RoundRobinUtils.getQueueObjName(objType),qId);
    				qMember.put('Name',memberName+'-'+position);
    				qMembers.add(qMember);
    			}
    		}
		}
		return qMembers;
	}

}