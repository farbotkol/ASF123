public class ECO_DTO_BudgetTask {
    public BudgetTask__c obudgetTask {get; set;}
    
    public Id id {
        get{return obudgetTask.ProjectTask__c;}
        private set;
    }
    
    public Id parentTaskId {
        get{return obudgetTask.ProjectTask__r.pse__Parent_Task__c;} 
        private set;
    }
    
    public String name {
        get{return obudgetTask.Name;} 
        private set;
    }
    
    public String taskNumber {
        get{return obudgetTask.ProjectTask__r.ProjectTaskNumber__c;} 
        private set;
    }
    
    public String taskName {
        get{return obudgetTask.ProjectTask__r.Name;} 
        private set;
    }

    private  Map<String, Decimal> values;

    public Decimal totalContingency {
    	get; 

    	set {
    		values.put('totalContingency', value);
    		totalContingency = value;
    	}
    }

    public Decimal totalContingencyRevenue {
    	get;

    	set {
    		values.put('totalContingencyRevenue', value);
    		totalContingencyRevenue = value;
    	}
    }

    public Decimal totalCost {
    	get;

    	set {
    		values.put('totalCost', value);
    		totalCost = value;
    	}
    }

    public Decimal totalComputedCost {
    	get;

    	set {
    		values.put('totalComputedCost', value);
    		totalComputedCost = value;
    	}
    }
    
    public Decimal totalFringe {
    	get;

    	set {
    		values.put('totalFringe', value);
    		totalFringe = value;
    	}
    }
    
    public Decimal totalFullyBurdenedLaborRate {
    	get;

    	set {
    		values.put('totalFullyBurdenedLaborRate', value);
    		totalFullyBurdenedLaborRate = value;
    	}
    }
    
    public Decimal totalLaborHours {
    	get;

    	set {
    		values.put('totalLaborHours', value);
    		totalLaborHours = value;
    	}
    }
    
    public Decimal totalODCCost {
    	get;

    	set {
    		values.put('totalODCCost', value);
    		totalODCCost = value;
    	}
    }

    public Decimal totalODCRevenue {
    	get;
    	
    	set {
    		values.put('totalODCRevenue', value);
    		totalODCRevenue = value;
    	}
    }

    public Decimal totalOverhead {
    	get;

    	set {
    		values.put('totalOverhead', value);
    		totalOverhead = value;
    	}
    }
    
    public Decimal totalRawCost {
    	get;

    	set {
    		values.put('totalRawCost', value);
    		totalRawCost = value;
    	}
    }
    
    public Decimal totalRevenue {
    	get;

    	set {
    		values.put('totalRevenue', value);
    		totalRevenue = value;
    	}
    }
    
    public Decimal totalSubCost {
    	get;

    	set {
    		values.put('totalSubCost', value);
    		totalSubCost = value;
    	}
    }

    public Decimal totalSubRevenue {
    	get;

    	set {
    		values.put('totalSubRevenue', value);
    		totalSubRevenue = value;
    	}
    }
    
    public Decimal totalLabourCost {
    	get;
    
    	set {
    		values.put('totalLabourCost', value);
    		totalLabourCost = value;
    	}
    }

    public Decimal totalLabourRevenue {
        get;

        set {
            values.put('totalLabourRevenue', value);
            totalLabourRevenue = value;
        }   
    }

    public Decimal totalEACActualCost {
    	get;

    	set {
    		values.put('totalEACActualCost', value);
    		totalEACActualCost = value;
    	}
    }


    public Decimal totalEACActualQuantity {
        get;

        set {
            values.put('totalEACActualQuantity', value);
            totalEACActualQuantity = value;
        }
    }

    public Decimal totalEACApprovedQuantity {
        get;

        set {
            values.put('totalEACApprovedQuantity', value);
            totalEACApprovedQuantity = value;
        }
    }

    public Decimal totalEACApprovedTotalCost {
        get;

        set {
            values.put('totalEACApprovedTotalCost', value);
            totalEACApprovedTotalCost = value;
        }
    }


    public Decimal totalEACForecastQuantity {
        get;

        set {
            values.put('totalEACForecastQuantity', value);
            totalEACForecastQuantity = value;
        }
    }

    public Decimal totalEACForecastRevenue {
        get;

        set {
            values.put('totalEACForecastRevenue', value);
            totalEACForecastRevenue = value;
        }
    }

    public Decimal totalEACForecastTotalCost {
        get;

        set {
            values.put('totalEACForecastTotalCost', value);
            totalEACForecastTotalCost = value;
        }
    }

    public Boolean hasChildren {
        get {
        return children.size() > 0 ? true: false;
        }
        private set;
    }

    public  ECO_DTO_BudgetTask parent {get; set;}
    public  List<ECO_DTO_BudgetTask> children {get; set;}
    public  Integer indentLevel {get; set;}

    public  String parentClasses {get; set;}

    public ECO_DTO_BudgetTask() {
    	values = new Map<String, Decimal>();
        children = new List<ECO_DTO_BudgetTask>();

        totalComputedCost = 0;
    }

    public ECO_DTO_BudgetTask(pse__Project_Task__c projectTask) {
        this();
        obudgetTask = new BudgetTask__c();
        obudgetTask.ProjectTask__c = projectTask.Id;
        obudgetTask.ProjectTask__r = projectTask;

        totalComputedCost = 0;
    }
    
    public ECO_DTO_BudgetTask(BudgetTask__c budgetTask) {
        obudgetTask = budgetTask;

    	values = new Map<String, Decimal>();

    	totalComputedCost = 0;
        
        totalContingency = obudgetTask.TotalContingency__c;
        totalContingencyRevenue = obudgetTask.TotalContingencyRevenue__c;
        totalCost = budgetTask.TotalCost__c;
        totalFringe = budgetTask.TotalFringe__c;
        totalFullyBurdenedLaborRate = budgetTask.TotalFullyBurdenedLaborRate__c;
        totalLaborHours = budgetTask.TotalLaborHours__c;
        totalODCCost = budgetTask.TotalODCCost__c;
        totalODCRevenue = budgetTask.TotalODCRevenue__c;

        totalOverhead = budgetTask.TotalOverhead__c;
        totalRawCost = budgetTask.TotalRawCost__c;
        totalRevenue = budgetTask.TotalRevenue__c;
        totalSubCost = budgetTask.TotalSubCost__c;
        totalSubRevenue = budgetTask.TotalSubRevenue__c;
        totalLabourCost = budgetTask.TotalLaborCost__c;
        totalLabourRevenue = budgetTask.TotalLaborRevenue__c;

        children = new List<ECO_DTO_BudgetTask>();
    }

    public Decimal getValueByName(String name) {
    	Decimal result = values.get(name);

    	if (result == null)
    		result = 0.0;

    	return result;
    }

    public void addChild(ECO_DTO_BudgetTask child) {
        children.add(child);
        child.parent = this;
    }

    public Decimal getSubtaskTotal(String fieldName) {
        return getSubtaskTotal(fieldName, true);
    }

    public Decimal getSubtaskTotal(String fieldName, boolean includeThis) {
        Decimal result = 0;

        if (includeThis && (children.size() == 0)) {
//            result += (Decimal) obudgetTask.get(fieldName);
			result += getValueByName(fieldName);
        }

        for (ECO_DTO_BudgetTask child : children) {
            result += child.getSubtaskTotal(fieldName);
        }

        return result;
    }
}