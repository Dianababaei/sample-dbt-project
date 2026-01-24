
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select quarter_end
from BAIN_ANALYTICS.DEV.report_lp_quarterly
where quarter_end is null



  
  
      
    ) dbt_internal_test