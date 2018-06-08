/**
* @desc: This class invokes from Order object trigger and 
         Create the Asset based on the OrderItem which are of Type = 'Vehicle'.
* @author: Abhinav
* @version: 1.0...
* 
*/
public class AssetCreation_old {
    //keep savepoint to ensure complete data entered
    Savepoint sp = Database.setSavepoint();
    Id orderId;
    List<Id> assetId = new List<Id>();
    List<Asset> assetlist = new List<Asset>();
    List<Asset_Owner__c>assetownerlist = new List<Asset_Owner__c>();
    //Id ContactId;
    /**
      *  This method invoke at the time of Order Status changed to 'Delivered' 
      *  This method will get Order as input and will fetch the Order items for creation of Asset
      */
    public List<Id> createAsset(Order order)
    {
        try
        {
            orderId = order.Id;
            List<OrderItem> Oli = [select Id, OrderItemNumber,Product2Id,Inventory_VIN__c,Engine__c from OrderItem where OrderId =: orderId AND Inventory_VIN__c != null AND Product2_Type__c = 'Vehicle'];
            for(OrderItem orditem:Oli){
                //create Asset instance and assign values to the Asset fields
                //These values can be changed based on the Region /country
                Asset asset = New Asset();
                asset.AccountId = order.AccountId;
                asset.CurrencyIsoCode = order.CurrencyIsoCode;
                asset.Country__c = order.Country__c;
                asset.AssetProvidedById = order.AccountId;
                asset.AssetServicedById = order.AccountId;
                /*Contact associated with the Asset -> this can be change to Shipped COntactId based on the
                Business Requirement in Region/ Country*/
                asset.ContactId = order.BillToContactId;
                asset.InstallDate = System.today();
                asset.PurchaseDate = System.today();
                asset.Price = order.TotalAmount;
                asset.OrderId__c = orderId;
                System.debug(Oli);
                //asset.Name can be changed based on the country/region
                asset.Name = order.OrderNumber;
                asset.Description = 'Asset from Order-> ' + order.OrderNumber + ' Order Item -> ' + orditem.OrderItemNumber; 
                asset.Product2Id = orditem.Product2Id;
                asset.SerialNumber = orditem.Inventory_VIN__c;
                asset.Engine__c = orditem.Engine__c;
                System.debug(asset);
                assetlist.add(asset);
            }
            //checking if Asset has any record to be inserted
            if(assetlist.size()>0){
                //insert Asset Record
               insert assetlist; 
            } 
            //INsert Asset Owner Record for tracking the Vehicle Users
            for(Asset aid:assetlist){
                assetId.add(aid.Id);
                Asset_Owner__c assetowner = New Asset_Owner__c();
                assetowner.Contact__c = order.BillToContactId;
                assetowner.Asset__c = aid.Id;
                assetowner.Name = aid.Name;
                assetownerlist.add(assetowner);
                //checking any assetowner to be inserted or not
                if(assetownerlist.size()>0)
                     insert assetownerlist; //insert Asset Owner Record
            }
        }
        catch(Exception e) 
        {
            //Rollback to avoid incomplete dataentry in the Database
            Database.rollback(sp);
            System.debug('An exception occurred: ' + e.getMessage());
        }
        //return Asset Id's
        return assetId;
    }
    
}