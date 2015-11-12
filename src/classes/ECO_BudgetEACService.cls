public class ECO_BudgetEACService
{
	public class EacException extends Exception {}

	private static BudgetHeader__c oBudgetHeader;
	private static Map<Id, BudgetTask__c> mBudgetTask;

	private static Map<String, BudgetResource__c> mapResourceByPTMId;
    private static Map<Id, BudgetResource__c> mapResourceBySubId;
    private static Map<String, BudgetResource__c> mapResourceByODCName;
    private static Map<String, BudgetResource__c> mapResourceByContingencyName;
    private static Map<String, List<BudgetAssignment__c>> mapAssignmentsByPTMId;
    private static Map<Id, List<BudgetAssignment__c>> mapAssignmentsBySubId;
    private static Map<String, List<BudgetAssignment__c>> mapAssignmentsByODCName;
    private static Map<String, List<BudgetAssignment__c>> mapAssignmentsByContingencyName;
    private static Map<String, BudgetAssignment__c> mapAssignmentByUniqueId;
    private static Map<String, BudgetResource__c> mapResourcesByPersonId;

    private static BudgetAssignment__c addOdcBA(String odcName, Id projectTaskId) {
		Id budgetTaskId = mBudgetTask.get(projectTaskId).Id;
	    BudgetResource__c budgetResource = mapResourceByODCName.get(odcName);
	    
	    if (budgetResource == null) {
	        budgetResource = new BudgetResource__c();
	        budgetResource.BudgetHeader__c = oBudgetHeader.id;
	        budgetResource.OverrideRatesOnLines__c = true;
	        budgetResource.ResourceType__c = 'ODC/FEE';
	        budgetResource.MarginType__c = 'Percent';
	        // TODO: ???
	        /* 		newBudgetColumn.OverrideUplift__c = markupPercentage;
					newBudgetColumn.ResourceName__c = jobName;
					newBudgetColumn.ExpenditureType__c = expenditureType;
					
					newBudgetColumn.CostCalcType__c = unitType;
					newBudgetColumn.OverrideRawCost__c = unitCost;
					newBudgetColumn.OverrideFringeMultiplier__c = 0.0;
					newBudgetColumn.OverrideOverheadMultiplier__c = 0.0;

					newBudgetColumn.isBillable__c = isBillable;
					newBudgetColumn.isEstimated__c = isEstimated;
					newBudgetColumn.isQuoted__c = isQuoted;
			*/
	        budgetResource.ResourceName__c = odcName;

	        mapResourceByODCName.put(odcName, budgetResource);
	    }
	                
	    List<BudgetAssignment__c> oAssignments = mapAssignmentsByODCName.get(odcName);
	    
	    if(oAssignments == null) {
	        oAssignments = new List<BudgetAssignment__c> ();
	        mapAssignmentsByODCName.put(odcName, oAssignments);               
	    }
	    
	    String uniqueId = odcName + '' + projectTaskId;
	    BudgetAssignment__c ba = mapAssignmentByUniqueId.get(uniqueId);
	    if (ba == null) {
	    	ba = new BudgetAssignment__c();
        	ba.EACApprovedTotalCost__c = 0;
        	ba.EACForecastTotalCost__c = 0;
	        mapAssignmentByUniqueId.put(uniqueId, ba);
	        oAssignments.add(ba); // make sure we only the BA once
	    }
	    
	    ba.BudgetTask__c = budgetTaskId;

	    return ba;
	}

	private static BudgetAssignment__c addSubBA(Id subId, Id projectTaskId) {
		Id budgetTaskId = mBudgetTask.get(projectTaskId).Id;
	    BudgetResource__c budgetResource = mapResourceBySubId.get(subId);
	    
	    if (budgetResource == null) {
	        budgetResource = new BudgetResource__c();
	        budgetResource.BudgetHeader__c = oBudgetHeader.id;
	        budgetResource.OverrideRatesOnLines__c = true;
	        budgetResource.ResourceType__c = 'Subcontractor';
	        // TODO: ???
	        // budgetResource.OverrideBillRate__c = theProject.DefaultBillRate__c;
	        // budgetResource.OverrideUplift__c = theProject.DefaultUpliftLabor__c;
	        budgetResource.JobName__c = null;

	        budgetResource.VendorSite__c  = subId;
	        mapResourceBySubId.put(subId, budgetResource);
	    }
	                
	    List<BudgetAssignment__c> oAssignments = mapAssignmentsBySubId.get(subId);
	    
	    if(oAssignments == null) {
	        oAssignments = new List<BudgetAssignment__c> ();
	        mapAssignmentsBySubId.put(subID, oAssignments);               
	    }
	    
	    String uniqueId = subId + '' + projectTaskId;
	    BudgetAssignment__c ba = mapAssignmentByUniqueId.get(uniqueId);
	    if (ba == null) {
	    	ba = new BudgetAssignment__c();
        	ba.EACApprovedTotalCost__c = 0;
        	ba.EACForecastTotalCost__c = 0;
	        mapAssignmentByUniqueId.put(uniqueId, ba);
	        oAssignments.add(ba); // make sure we only the BA once
	    }
	    
	    ba.BudgetTask__c = budgetTaskId;

	    return ba;
	}
	private static List<String> oracleSubsName;
  private static List<String> oracleLabNames;

	private static void createExpTypes() {
		oracleSubsName = new List<String>();
    oracleLabNames = new List<String>();
		Map<String, Oracle_Expenditure_Types__c> typesMap = Oracle_Expenditure_Types__c.getAll();
		for (Oracle_Expenditure_Types__c expType : typesMap.values()) {
			String rollupType = expType.Rollup_Type_1__c;
			String name = expType.Expenditure_Type__c;

			if (rollupType == 'SUBS') {
				oracleSubsName.add(name);
			} else if (rollupType == 'LAB') {
        oracleLabNames.add(name);
      }
		}
	}

    // Return Id of new budget header created
	public static Id createInitECO(Id sProjectId) {
		createExpTypes();

		mapResourceByPTMId = new Map <String, BudgetResource__c> ();
        mapResourceBySubId = new Map <Id, BudgetResource__c> ();
        mapResourceByContingencyName = new Map <String, BudgetResource__c> ();
        mapResourceByODCName = new Map <String, BudgetResource__c> ();
        // Stores BAs so we can set the BudgetResource__c Id after the records are inserted
        mapAssignmentsByPTMId = new Map <String, List<BudgetAssignment__c>> ();
        mapAssignmentsBySubId = new Map <Id, List<BudgetAssignment__c>> ();
        mapAssignmentsByContingencyName = new Map <String, List<BudgetAssignment__c>> ();
        mapAssignmentsByODCName = new Map <String, List<BudgetAssignment__c>> ();
        
        mapAssignmentByUniqueId = new Map <String, BudgetAssignment__c> ();

        mapResourcesByPersonId = new Map<String, BudgetResource__c>();

		//ECO_DTO_BudgetLabourWrapper budgetLabourWrapper = new budgetLabourWrapper(projectId);
		oBudgetHeader = new BudgetHeader__c();
        oBudgetHeader.RecordTypeId = ECO_Utils_Meta.getRecordTypeId(BudgetHeader__c.sObjectType, 'EAC');
        oBudgetHeader.Project__c = sProjectId;
        oBudgetHeader.Status__c = 'Estimate';
        
        list<BudgetHeader__c> lBudgetHeader = new list<BudgetHeader__c>([SELECT Id FROM BudgetHeader__c WHERE Project__c = :sProjectId]);
        
        oBudgetHeader.BudgetName__c = 'EAC ' + lBudgetHeader.size();
        insert oBudgetHeader;
        
        mBudgetTask = new Map<Id, BudgetTask__c>();
        Map<String, ProjectTeamMember__c> mapPTMByPersonId = new Map<String, ProjectTeamMember__c> ();
        Map<String, VendorSite__c> mapVSbyVendorId = new Map<String, VendorSite__c> ();


        Set<Id> PTMIdsInBudget = new Set<Id>();
        Set<Id> VendorIdsInBudget = new Set<Id>();

        for (pse__Project_Task__c oProjectTask : [SELECT Id, Name 
                                                  FROM pse__Project_Task__c 
                                                  WHERE pse__Project__c = :sProjectId]) {
                                                      
                                                      BudgetTask__c oBudgetTask = new BudgetTask__c();
                                                      oBudgetTask.ProjectTask__c = oProjectTask.Id;
                                                      oBudgetTask.BudgetHeader__c = oBudgetHeader.Id;
                                                      oBudgetTask.TaskName__c = oProjectTask.Name;
                                                      mBudgetTask.put(oProjectTask.Id, oBudgetTask);
                                                  }
        

        if (!mBudgetTask.isEmpty()) {
            insert mBudgetTask.values();
        }
        list<RecordType> lstRT = [select id from recordtype where sObjectType='ChangeManager__c' and developername='InternalChange'];

        // TODO: Make sure assumption that every Account and User has an associated oracle id is true. if not we should account for it in the code.
      	// Link Person Ids from PTMs
        for (ProjectTeamMember__c ptm : [Select Id, OraclePersonId__c, Project__c From ProjectTeamMember__c Where Project__c = :sProjectId]) {
        	mapPTMByPersonId.put(ptm.OraclePersonId__c, ptm);
        }

      	// Link Vendor Ids from VS 
        for (VendorSite__c vs : [Select Id, Site__r.Account__r.OracleVendorID__c, Project__c From VendorSite__c Where Project__c = :sProjectId]) {
        	mapVSbyVendorId.put(vs.Site__r.Account__r.OracleVendorID__c, vs);
        }

        AggregateResult[] arTotals = [Select Sum(Quantity__c) Quantity__c, Sum(FullyBurdenedCost__c) FullyBurdenedCost__c, BudgetTask__r.ProjectTask__c, BudgetResource__r.ProjectTeamMember__c, BudgetTask__r.BudgetHeader__r.Status__c
                                      From BudgetAssignment__c 
                                      Where BudgetTask__r.ProjectTask__r.pse__Project__c = :sProjectId AND ResourceType__c = 'Labor/Person' AND
                                      		(BudgetTask__r.BudgetHeader__r.Status__c = 'Forecast' OR BudgetTask__r.BudgetHeader__r.Status__c = 'Approved') 
                                      GROUP BY BudgetTask__r.ProjectTask__c, BudgetResource__r.ProjectTeamMember__c, BudgetTask__r.BudgetHeader__r.Status__c
                                     ];
        
        AggregateResult[] arSubs = [Select Sum(OverrideTotalCost__c) OverrideTotalCost__c, BudgetTask__r.ProjectTask__c, BudgetResource__r.VendorSite__c, BudgetTask__r.BudgetHeader__r.Status__c 
                                      From BudgetAssignment__c 
                                      Where BudgetTask__r.ProjectTask__r.pse__Project__c = :sProjectId AND ResourceType__c = 'Subcontractor' AND
                                      		(BudgetTask__r.BudgetHeader__r.Status__c = 'Forecast' OR BudgetTask__r.BudgetHeader__r.Status__c = 'Approved') 
                                      GROUP BY BudgetTask__r.ProjectTask__c, BudgetResource__r.VendorSite__c, BudgetTask__r.BudgetHeader__r.Status__c
                                     ];

     	AggregateResult[] arContingency = [Select Sum(OverrideTotalCost__c) OverrideTotalCost__c, BudgetTask__r.ProjectTask__c, BudgetResource__r.JobName__c, BudgetTask__r.BudgetHeader__r.Status__c 
                                      From BudgetAssignment__c 
                                      Where BudgetTask__r.ProjectTask__r.pse__Project__c = :sProjectId AND ResourceType__c='Contingency' AND  
                                      		(BudgetTask__r.BudgetHeader__r.Status__c = 'Forecast' OR BudgetTask__r.BudgetHeader__r.Status__c = 'Approved') 
                                      GROUP BY BudgetTask__r.ProjectTask__c, BudgetResource__r.JobName__c, BudgetTask__r.BudgetHeader__r.Status__c
                                     ];
       


        AggregateResult[] arODC = [Select Sum(OverrideTotalCost__c) OverrideTotalCost__c, BudgetTask__r.ProjectTask__c, BudgetResource__r.ResourceName__c, BudgetTask__r.BudgetHeader__r.Status__c 
                                      From BudgetAssignment__c 
                                      Where BudgetTask__r.ProjectTask__r.pse__Project__c = :sProjectId AND ResourceType__c = 'ODC/FEE' AND
                                      		(BudgetTask__r.BudgetHeader__r.Status__c = 'Forecast' OR BudgetTask__r.BudgetHeader__r.Status__c = 'Approved') 
                                      GROUP BY BudgetTask__r.ProjectTask__c, BudgetResource__r.ResourceName__c, BudgetTask__r.BudgetHeader__r.Status__c];
                                      
        AggregateResult[] arLaborActuals = [SELECT PersonId__c, SUM(Quantity__c) Quantity__c, SUM(ProjectFunctionalRawCost__c) totalRawCost, ProjectTask__c,VendorId__c 
                                            FROM ExpendItem__c Where Project__c = :sProjectId AND ExpenditureType__c IN :oracleLabNames
                                            GROUP BY ProjectTask__c, VendorId__c, PersonId__c
                                     ];

        AggregateResult[] arSubActuals = [SELECT PersonId__c, SUM(Quantity__c) Quantity__c, SUM(ProjectFunctionalRawCost__c) totalRawCost, ProjectTask__c,VendorId__c 
        								FROM ExpendItem__c Where Project__c = :sProjectId AND ExpenditureType__c IN :oracleSubsName 
        								GROUP BY ProjectTask__c, VendorId__c, PersonId__c
                                     ];



		for (AggregateResult ar : arSubs) {
            Id subId = (Id)ar.get('VendorSite__c');

            if (subId != null) VendorIdsInBudget.add(subId);
        }

        Set<String> vendorIdsToAdd = new Set<String>();

        List<ProjectTeamMember__c> vendorSitesToAdd = new List<ProjectTeamMember__c>();

        for (AggregateResult ar : arSubActuals) {
        	String vendorId = (String)ar.get('VendorId__c');

        	if (vendorId == null) {
        		throw new EacException('VendorId is null on Expenditure Item');
        	}
        	
        	VendorSite__c vs = mapVSbyVendorId.get(vendorId);

        	if (vs == null || !VendorIdsInBudget.contains(vs.Id)) {
        		vendorIdsToAdd.add(vendorId);
        	}
        }

        if (!vendorIdsToAdd.isEmpty()) {
        	// TODO: Implement adding vendor site

        	throw new EacException('Vendor Site found on expenditure item not in budget');
        	/*ProjectRole__c prl = [select id from ProjectRole__c where Name = 'Task Manager'];

	        for (Contact con : [Select Id, pse__Salesforce_User__r.PersonId__c From Contact Where pse__Salesforce_User__r.PersonId__c in :personIdsToAdd]) {
				ProjectTeamMember__c ptm = new ProjectTeamMember__c();
				ptm.contact__c = con.Id;
				ptm.project__c = sProjectId;
				ptm.ProjectRole__c = prl.id;

				ptmsToAdd.add(ptm);
				mapPTMByPersonId.put(con.pse__Salesforce_User__r.PersonId__c, ptm);
	        }

	        insert ptmsToAdd;*/
		}

	 	for (AggregateResult ar : arSubActuals) {
        	Id projectTaskId = (Id)ar.get('ProjectTask__c');
            String vendorId = (String)ar.get('VendorId__c');
            
            if (vendorId == 'null' || projectTaskId == null) continue;

            Id subId = mapVSByVendorId.get(vendorId).Id;

            Decimal totalRawCost = (Decimal)ar.get('totalRawCost');
            
            BudgetAssignment__c ba = addSubBA(subId, projectTaskId);

            ba.EACActualCost__c = totalRawCost;
        }

        for (AggregateResult ar : arODC) {
        	Id projectTaskId = (Id)ar.get('ProjectTask__c');
            String odcName = (String)ar.get('ResourceName__c');
            
            if (odcName == null || projectTaskId == null) continue;
            String status = (String)ar.get('Status__c');
            Decimal quantity = (Decimal)ar.get('OverrideTotalCost__c');
            
            
            BudgetAssignment__c ba = addOdcBA(odcName, projectTaskId);

            if (status == 'Approved') {
         		ba.EACApprovedTotalCost__c  = quantity;
            } else if (status == 'Forecast') {
            	ba.EACForecastTotalCost__c  = quantity;
            }          
            
        }

        for (AggregateResult ar : arContingency) {
        	Id projectTaskId = (Id)ar.get('ProjectTask__c');
            String contName = (String)ar.get('JobName__c');
            
            if (contName == null || projectTaskId == null) continue;
            String status = (String)ar.get('Status__c');
            Decimal quantity = (Decimal)ar.get('OverrideTotalCost__c');
            Id budgetTaskId = mBudgetTask.get(projectTaskId).Id;
            BudgetResource__c budgetResource = mapResourceByContingencyName.get(contName);
            
            if (budgetResource == null) {
                budgetResource = new BudgetResource__c();
                budgetResource.BudgetHeader__c = oBudgetHeader.id;
                budgetResource.OverrideRatesOnLines__c = true;
                budgetResource.ResourceType__c = 'Contingency';
                // TODO: ???
                // budgetResource.OverrideBillRate__c = theProject.DefaultBillRate__c;
                // budgetResource.OverrideUplift__c = theProject.DefaultUpliftLabor__c;
                budgetResource.JobName__c = contName;

                mapResourceByContingencyName.put(contName, budgetResource);
            }
                        
            List<BudgetAssignment__c> oAssignments = mapAssignmentsByContingencyName.get(contName);
            
            if(oAssignments == null) {
                oAssignments = new List<BudgetAssignment__c> ();
                mapAssignmentsByContingencyName.put(contName, oAssignments);               
            }
            
            String uniqueId = contName + '' + projectTaskId;
            BudgetAssignment__c ba = mapAssignmentByUniqueId.get(uniqueId);
            if (ba == null) {
            	ba = new BudgetAssignment__c();
            	ba.EACApprovedTotalCost__c = 0;
            	ba.EACForecastTotalCost__c = 0;
                mapAssignmentByUniqueId.put(uniqueId, ba);
                oAssignments.add(ba); // make sure we only the BA once
            }
            
            ba.BudgetTask__c = budgetTaskId;
            if (status == 'Approved') {
         		ba.EACApprovedTotalCost__c  = quantity;
            } else if (status == 'Forecast') {
            	ba.EACForecastTotalCost__c  = quantity;
            }          
            
        }


        for (AggregateResult ar : arSubs) {
        	Id projectTaskId = (Id)ar.get('ProjectTask__c');
            Id subId = (Id)ar.get('VendorSite__c');
            
            if (subId == null || projectTaskId == null) continue;
            String status = (String)ar.get('Status__c');
            Decimal quantity = (Decimal)ar.get('OverrideTotalCost__c');
            
            
            BudgetAssignment__c ba = addSubBA(subId, projectTaskId);
            /*
            Id budgetTaskId = mBudgetTask.get(projectTaskId).Id;
            BudgetResource__c budgetResource = mapResourceBySubId.get(subId);
            
            if (budgetResource == null) {
                budgetResource = new BudgetResource__c();
                budgetResource.BudgetHeader__c = oBudgetHeader.id;
                budgetResource.OverrideRatesOnLines__c = true;
                budgetResource.ResourceType__c = 'Subcontractor';
                // TODO: ???
                // budgetResource.OverrideBillRate__c = theProject.DefaultBillRate__c;
                // budgetResource.OverrideUplift__c = theProject.DefaultUpliftLabor__c;
                budgetResource.JobName__c = null;

                budgetResource.VendorSite__c  = subId;
                mapResourceBySubId.put(subId, budgetResource);
            }
                        
            List<BudgetAssignment__c> oAssignments = mapAssignmentsBySubId.get(subId);
            
            if(oAssignments == null) {
                oAssignments = new List<BudgetAssignment__c> ();
                mapAssignmentsBySubId.put(subID, oAssignments);               
            }
            
            String uniqueId = subId + '' + projectTaskId;
            BudgetAssignment__c ba = mapAssignmentByUniqueId.get(uniqueId);
            if (ba == null) {
            	ba = new BudgetAssignment__c();
                mapAssignmentByUniqueId.put(uniqueId, ba);
                oAssignments.add(ba); // make sure we only the BA once
            }
            
            ba.BudgetTask__c = budgetTaskId;
            */

            if (status == 'Approved') {
         		ba.EACApprovedTotalCost__c  = quantity;
            } else if (status == 'Forecast') {
            	ba.EACForecastTotalCost__c  = quantity;
            }          
            
        }

        for (AggregateResult ar : arTotals) {
        	Id ptmId = (Id)ar.get('ProjectTeamMember__c');

            if (ptmId != null) PTMIdsInBudget.add(ptmId);
        }

        Set<String> personIdsToAdd = new Set<String>();

        List<ProjectTeamMember__c> ptmsToAdd = new List<ProjectTeamMember__c>();

        for (AggregateResult ar : arLaborActuals) {
        	String personId = (String)ar.get('PersonId__c');

        	if (personId == null) {
        		throw new EacException('PersonId is null on Expenditure Item');
        	}
        	
        	ProjectTeamMember__c ptm = mapPTMByPersonId.get(personId);

          if (ptm == null) {            
            mapPTMByPersonId.put(personId, null);
            personIdsToAdd.add(personId);
        	} else if (!PTMIdsInBudget.contains(ptm.Id)) {
        		personIdsToAdd.add(personId);
        	}
        }

        if (!personIdsToAdd.isEmpty()) {
        	ProjectRole__c prl = [select id from ProjectRole__c where Name = 'Task Manager'];

	        for (Contact con : [Select Id, pse__Salesforce_User__r.PersonId__c From Contact Where pse__Salesforce_User__r.PersonId__c in :personIdsToAdd]) {
    				ProjectTeamMember__c ptm = new ProjectTeamMember__c();
    				ptm.contact__c = con.Id;
    				ptm.project__c = sProjectId;
    				ptm.ProjectRole__c = prl.id;

    				ptmsToAdd.add(ptm);
    				mapPTMByPersonId.put(con.pse__Salesforce_User__r.PersonId__c, ptm);
	        }

	        insert ptmsToAdd;
		}

		for (AggregateResult ar : arLaborActuals) {
			String personId = (String)ar.get('PersonId__c');
        	Decimal quantity = (Decimal)ar.get('Quantity__c');
        	Decimal totalRawCost = (Decimal)ar.get('totalRawCost');
        	Id projectTaskId = (Id)ar.get('ProjectTask__c');
            Id budgetTaskId = mBudgetTask.get(projectTaskId).Id;
            ProjectTeamMember__c ptm =  mapPTMByPersonId.get(personId);
            BudgetResource__c budgetResource;
            String ptmId;

            if (ptm != null) {
              ptmId = ptm.Id;
            } else {
              ptmId = personId;
            }

            budgetResource = mapResourceByPTMId.get(personId);
            if (budgetResource == null) {
                budgetResource = new BudgetResource__c();
                budgetResource.BudgetHeader__c = oBudgetHeader.id;
                budgetResource.OverrideRatesOnLines__c = true;
                budgetResource.ResourceType__c = 'Labor/Person';
                // TODO: ???
                // budgetResource.OverrideBillRate__c = theProject.DefaultBillRate__c;
                // budgetResource.OverrideUplift__c = theProject.DefaultUpliftLabor__c;

                if (ptm != null) {
                  budgetResource.ProjectTeamMember__c = ptmId;
                } else {
                  budgetResource.JobName__c = 'Error: No contact with Oracle Person ID - ' + personId;
                }

                mapResourceByPTMId.put(ptmId, budgetResource);
            }
                        
            List<BudgetAssignment__c> oAssignments = mapAssignmentsByPTMId.get(ptmId);
            
            if(oAssignments == null) {
                oAssignments = new List<BudgetAssignment__c> ();
                mapAssignmentsByPTMId.put(ptmID, oAssignments);               
            }
            
            String uniqueId = ptmId + '' + projectTaskId;
            BudgetAssignment__c ba = mapAssignmentByUniqueId.get(uniqueId);
            if (ba == null) {
            	ba = new BudgetAssignment__c();
          		ba.EACApprovedTotalCost__c = 0;
        			ba.EACForecastTotalCost__c = 0;
        			ba.EACApprovedQuantity__c = 0;
        			ba.EACForecastQuantity__c = 0;
              mapAssignmentByUniqueId.put(uniqueId, ba);
              oAssignments.add(ba); // make sure we only the BA once
            }
            
            ba.BudgetTask__c = budgetTaskId;

            ba.EACActualQuantity__c = quantity;
            ba.EACActualCost__c = totalRawCost;
		}

        for (AggregateResult ar : arTotals) {
        	Id projectTaskId = (Id)ar.get('ProjectTask__c');
            Id ptmId = (Id)ar.get('ProjectTeamMember__c');
            
            if (projectTaskId == null) continue;

            if (ptmId != null) PTMIdsInBudget.add(ptmId);

            String status = (String)ar.get('Status__c');
            Decimal quantity = (Decimal)ar.get('Quantity__c');
            Decimal totalCost = (Decimal)ar.get('FullyBurdenedCost__c');
            totalCost = totalCost == null ? 0 : totalCost;

            Id budgetTaskId = mBudgetTask.get(projectTaskId).Id;
            BudgetResource__c budgetResource = mapResourceByPTMId.get(ptmId);
            
            if (budgetResource == null) {
                budgetResource = new BudgetResource__c();
                budgetResource.BudgetHeader__c = oBudgetHeader.id;
                budgetResource.OverrideRatesOnLines__c = true;
                budgetResource.ResourceType__c = 'Labor/Person';
                // TODO: ???
                // budgetResource.OverrideBillRate__c = theProject.DefaultBillRate__c;
                // budgetResource.OverrideUplift__c = theProject.DefaultUpliftLabor__c;
                budgetResource.JobName__c = null;

                budgetResource.ProjectTeamMember__c = ptmId;
                mapResourceByPTMId.put(ptmId, budgetResource);
            }
                        
            List<BudgetAssignment__c> oAssignments = mapAssignmentsByPTMId.get(ptmId);
            
            if(oAssignments == null) {
                oAssignments = new List<BudgetAssignment__c> ();
                mapAssignmentsByPTMId.put(ptmID, oAssignments);               
            }
            
            String uniqueId = ptmId + '' + projectTaskId;
            BudgetAssignment__c ba = mapAssignmentByUniqueId.get(uniqueId);
            if (ba == null) {
            	ba = new BudgetAssignment__c();
        		ba.EACApprovedTotalCost__c = 0;
    			ba.EACForecastTotalCost__c = 0;
    			ba.EACApprovedQuantity__c = 0;
    			ba.EACForecastQuantity__c = 0;
                mapAssignmentByUniqueId.put(uniqueId, ba);
                oAssignments.add(ba); // make sure we only the BA once
            }
            
            ba.BudgetTask__c = budgetTaskId;
            if (status == 'Approved') {
         		ba.EACApprovedQuantity__c = quantity;
         		ba.EACApprovedTotalCost__c = totalCost;
            } else if (status == 'Forecast') {
            	ba.EACForecastQuantity__c = quantity;
            	ba.EACForecastTotalCost__c = totalCost;
            }          
            
        }
       
        // Insert All budgetResources
        List<BudgetResource__c> allBudgets = new List<BudgetResource__c>();
        allBudgets.addAll(mapResourceByPTMId.values());
        allBudgets.addAll(mapResourceByContingencyName.values());
        allBudgets.addAll(mapResourceBySubId.values());
        allBudgets.addAll(mapResourceByODCName.values());
        insert allBudgets;
        
		//insert mapResourceBySubId.values();
        //insert mapResourceByContingencyName.values();

        for (String contName : mapResourceByContingencyName.keySet()) {
            Id brId = mapResourceByContingencyName.get(contName).Id;
            
            for(BudgetAssignment__c ba : mapAssignmentsByContingencyName.get(contName)) {
                ba.BudgetResource__c = brId;
            }
        }

        for (String odcName : mapResourceByODCName.keySet()) {
            Id brId = mapResourceByODCName.get(odcName).Id;
            
            for(BudgetAssignment__c ba : mapAssignmentsByODCName.get(odcName)) {
                ba.BudgetResource__c = brId;
            }
        }

        for (Id subId : mapResourceBySubId.keySet()) {
            Id brId = mapResourceBySubId.get(subId).Id;
            
            for(BudgetAssignment__c ba : mapAssignmentsBySubId.get(subId)) {
                ba.BudgetResource__c = brId;
            }
        }
        
        for (String ptmId : mapResourceByPTMId.keySet()) {
            Id brId = mapResourceByPTMId.get(ptmId).Id;
            
            for(BudgetAssignment__c ba : mapAssignmentsByPTMId.get(ptmId)) {
                ba.BudgetResource__c = brId;
            }
        }
        
        for (BudgetAssignment__c ba : mapAssignmentByUniqueId.values()) {
        	ba.EACForecastTotalCost__c = ifNull(ba.EACApprovedTotalCost__c) + ifNull(ba.EACForecastTotalCost__c);
        	ba.EACForecastQuantity__c = ifNull(ba.EACApprovedQuantity__c) + ifNull(ba.EACForecastQuantity__c);
        }

        // Insert All Budget Asssignments
        insert mapAssignmentByUniqueId.values();
        
        return oBudgetHeader.Id;
	}

	private static Decimal ifNull(Decimal val) {
		return val == null ? 0 : val;
	}
}