CREATE DEFINER=`root`@`%` PROCEDURE `small_core_leo`.`gen_overdue_30_180_amt`()
BEGIN
		
	
	DECLARE v_PROJECT_ID varchar(64); 
    DECLARE v_PERIOD INT(11); 
    DECLARE v_day_count INT(11); 
    DECLARE v_PLAN_REPAY_DT varchar(10); 
   	DECLARE v_PRI INT(11); 
   	DECLARE v_START_DT varchar(10); 
  	DECLARE v_END_DT varchar(10); 
  
   	DECLARE v_PAID_30 INT(11);  
   	DECLARE v_PAID_60 INT(11);  
  	DECLARE v_PAID_90 INT(11);  
 	DECLARE v_PAID_180 INT(11); 
 	
 
	DECLARE v_month_diff INT(11);
	DECLARE done INT DEFAULT 0; 
    

	-- 1. 找出逾期天数已经超过31天的项目和期（实际上，最后一期之后的因为当期本金为0，无实际意义，但不好挑出来，不一并计算
	DECLARE cur CURSOR FOR (
		SELECT aa.ProjectID, aa.Peroid, aa.over_day_count, aa.PLAN_REPAY_DT, bb.RECEIPT_AMOUNT_IT FROM 
			tmp_overdue aa, tmp_project_period_prin bb
		WHERE 
			aa.ProjectID = bb.PROJECT_ID
			and aa.Peroid = bb.PERIOD
			and aa.over_day_count >= 31
		GROUP by ProjectID , Peroid
	);

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1; 

    OPEN cur;
    read_loop:LOOP 
        FETCH cur INTO v_PROJECT_ID, v_PERIOD, v_day_count, v_PLAN_REPAY_DT, v_PRI; 
        IF done = 1 THEN 
            LEAVE read_loop; 
        END IF; 
       	
	       	
	       	-- 计算期间还本金
	       	set v_PAID_30 = ifnull( (SELECT sum(PAID_PRIN_AMT) 
	       					from tmp_repay_instmnt 
	       					WHERE PROJECT_ID = v_PROJECT_ID and PERIOD = v_PERIOD
	       					AND REPAY_DATE < date_add(v_PLAN_REPAY_DT, interval 31 DAY )), 0);
	       	set v_PAID_60 = ifnull( (SELECT sum(PAID_PRIN_AMT) 
	       					from tmp_repay_instmnt 
	       					WHERE PROJECT_ID = v_PROJECT_ID and PERIOD = v_PERIOD
	       					AND REPAY_DATE < date_add(v_PLAN_REPAY_DT, interval 61 DAY )), 0);
	       	set v_PAID_90 = ifnull( (SELECT sum(PAID_PRIN_AMT) 
	       					from tmp_repay_instmnt 
	       					WHERE PROJECT_ID = v_PROJECT_ID and PERIOD = v_PERIOD
	       					AND REPAY_DATE < date_add(v_PLAN_REPAY_DT, interval 91 DAY )), 0);
	       	set v_PAID_180 = ifnull( (SELECT sum(PAID_PRIN_AMT) 
	       					from tmp_repay_instmnt 
	       					WHERE PROJECT_ID = v_PROJECT_ID and PERIOD = v_PERIOD
	       					AND REPAY_DATE < date_add(v_PLAN_REPAY_DT, interval 181 DAY )), 0);
	       
	       				
-- 	    set @N = 0;
-- 		set @exeSql = 'UPDATE tmp_overdue SET';
	
       	if v_day_count >= 31 and v_day_count <= 60 THEN 
--        		set @N = 1;
       		-- set @exeSql=concat( @exeSql, ' OVERDUE31_60DAYS_AMT=', (v_PRI - v_PAID_30)) ;
       		UPDATE tmp_overdue SET
       			OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30 -- ,
       			-- OVERDUE61_90DAYS_AMT 	= 0,
       			-- OVERDUE91_180DAYS_AMT 	= 0,
       			-- OVERDUE_180DAYS_AMT  	= 0
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD;
       	elseif v_day_count >= 61 and v_day_count <= 90 THEN 
--        		set @N = 2;       
			UPDATE tmp_overdue SET 
       			OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30 -- ,
       			-- OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
       			-- OVERDUE91_180DAYS_AMT 	= 0,
       			-- OVERDUE_180DAYS_AMT  	= 0
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD;
       	
       		UPDATE tmp_overdue SET 
       			-- OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30,
       			OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60 -- ,
       			-- OVERDUE91_180DAYS_AMT 	= 0,
       			-- OVERDUE_180DAYS_AMT  	= 0
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD + 1;
       	
        elseif v_day_count >= 91 and v_day_count <= 180 THEN 
--        		set @N = 3;       	
       		UPDATE tmp_overdue SET 
       			OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30 -- ,
       			-- OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
       			-- OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90,
       			-- OVERDUE_180DAYS_AMT  	= 0
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD;
       	
       		UPDATE tmp_overdue SET 
       			-- OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30,
       			OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60 -- , 
       			-- OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90,
       			-- OVERDUE_180DAYS_AMT  	= 0
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD+1;
       	
       		UPDATE tmp_overdue SET 
       			-- OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30,
       			-- OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
       			OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90 -- ,
       			-- OVERDUE_180DAYS_AMT  	= 0
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD+2;
        else -- v_day_count >= 181 THEN 
--        		set @N = 4;    
       		UPDATE tmp_overdue SET 
       			OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30 -- ,
       			-- OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
       			-- OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90,
       			--  OVERDUE_180DAYS_AMT  	= v_PRI - v_PAID_180
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD;
       		
       		UPDATE tmp_overdue SET 
       			-- OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30,
       			OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60 -- ,
       			-- OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90,
       			-- OVERDUE_180DAYS_AMT  	= v_PRI - v_PAID_180
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD+1;
       	
       		UPDATE tmp_overdue SET 
       			-- OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30,
       			-- OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
       			OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90 -- ,
       			-- OVERDUE_180DAYS_AMT  	= v_PRI - v_PAID_180
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD+2;
       	
       		UPDATE tmp_overdue SET 
       			-- OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30,
       			-- OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
       			-- OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90,
       			OVERDUE_180DAYS_AMT  	= v_PRI - v_PAID_180
       		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD+3;
       	end if;
	       				
-- 	        set @exeSql=concat( @exeSql, ' WHERE ProjectID=''', v_PROJECT_ID);
-- 	       	set @exeSql=concat( @exeSql, ''' and Peroid=', v_PERIOD );				
-- 	       	prepare stmt from @exeSql;
--             EXECUTE stmt;
--             deallocate prepare stmt;
--        		UPDATE tmp_overdue SET @SQL_COND
--        			OVERDUE31_60DAYS_AMT 	= v_PRI - v_PAID_30, 
--        			OVERDUE61_90DAYS_AMT 	= v_PRI - v_PAID_60,
--        			OVERDUE91_180DAYS_AMT 	= v_PRI - v_PAID_90,
--        			OVERDUE_180DAYS_AMT  	= v_PRI - v_PAID_180
--        		where ProjectID = v_PROJECT_ID and Peroid = v_PERIOD;
       	
--        		set @n = @n + 1;
--        	end while;

	END LOOP read_loop;
    CLOSE cur; 

END