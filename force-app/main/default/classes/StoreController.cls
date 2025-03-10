public with sharing class StoreController {
  private static final Integer DEFAULT_PAGE_SIZE = 9;

  /**
   * Endpoint that retrieves a paged and filtered list of stores
   * @param searchKey String used for searching on store name and owner
   * @param type Storefront type
   * @param cuisine Storefront cuisine
   * @param minReviewScore Minimum review score
   * @param pageSize Number of stores per page
   * @param pageNumber Page number
   * @return PagedResult object holding the paged and filtered list of stores
   */
  @AuraEnabled(cacheable=true scope='global')
  public static PagedResult getPagedStoreList(
    String searchKey,
    String type,
    String cuisine,
    Integer minReviewScore,
    Integer pageSize,
    Integer pageNumber
  ) {
    // Normalize inputs
    Integer safePageSize = pageSize ?? DEFAULT_PAGE_SIZE;
    Integer safePageNumber = pageNumber ?? 1;
    String searchPattern = '%' + searchKey + '%';
    Integer offset = (safePageNumber - 1) * safePageSize;

    // Prepare filter conditions
    List<String> conditions = new List<String>();
    if (!String.isBlank(searchKey)) {
      conditions.add(
        '(Name LIKE :searchPattern OR Address__City__s LIKE :searchPattern)'
      );
    }
    if (!String.isBlank(type)) {
      conditions.add('Type__c >= :type');
    }
    if (!String.isBlank(cuisine)) {
      conditions.add('Cuisine__c = :cuisine');
    }
    if (minReviewScore != null) {
      conditions.add('Average_Review_Score__c >= :minReviewScore');
    }

    // Count records
    String countQuery = 'SELECT COUNT() FROM Storefront__c ';
    if (conditions.size() > 0) {
      countQuery += 'WHERE ' + String.join(conditions, ' AND ');
    }
    countQuery += ' WITH USER_MODE';
    Integer totalItemCount = Database.countQuery(countQuery);

    // Retrieve records
    String query = 'SELECT Id, Name, Account__c, Address__City__s, Average_Review_Score__c, Description__c, Menu_Count__c, Phone__c, Primary_Contact__c, Status__c, Total_Reviews__c, Total_Score__c, Type__c, Thumbnail__c FROM Storefront__c ';
    if (conditions.size() > 0) {
      query += 'WHERE ' + String.join(conditions, ' AND ');
    }
    query +=
      ' WITH USER_MODE' +
      ' ORDER BY Name' +
      ' LIMIT :safePageSize' +
      ' OFFSET :offset';
    List<Storefront__c> stores = Database.query(query);

    // Return paginated results
    PagedResult result = new PagedResult();
    result.pageSize = safePageSize;
    result.pageNumber = safePageNumber;
    result.totalItemCount = totalItemCount;
    result.records = stores;
    return result;
  }
}
