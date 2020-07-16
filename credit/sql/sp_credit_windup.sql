CREATE DEFINER=`root`@`%` PROCEDURE `small_core`.`sp_credit_wind_up`(IN EXEC_DATE datetime)
BEGIN
	
-- 征信上报收尾工作
SET @OVERDUE_DAYS = 10; 
## -- 1. 设置导出时间
set @EXPORT_DATE=DATE_FORMAT(NOW() , '%Y-%m-%d');
-- 10号前
if EXEC_DATE is not null then
	set @EXPORT_DATE=DATE_FORMAT(EXEC_DATE , '%Y-%m-%d');
	if EXEC_DATE < '2020-06-10' then
		SET @OVERDUE_DAYS = 1; 
	end if;
end if;

set @EXPORT_START_DATE=DATE_FORMAT(date_add(@EXPORT_DATE, interval 0 - @OVERDUE_DAYS day)  , '%Y-%m-%d');
-- 清理结清状态的项目
-- 从  tmp_overdue_projects 中结清项目（设置settle_flag=1）
UPDATE tmp_overdue_repo 
	set settle_flag=100
	-- SELECT * FROM tmp_overdue_repo
	WHERE PROJECT_ID IN (SELECT top.PROJECT_ID FROM APPLY_ORDER ao, tmp_overdue_projects top WHERE ao.APPLY_NO = top.PROJECT_ID AND ao.APPLY_STATUS in (12, 13) AND ao.END_DATE <=@EXPORT_DATE);

UPDATE tmp_overdue_repo 
	set settle_flag=100
	-- SELECT * FROM tmp_overdue_repo
	WHERE PROJECT_ID IN (SELECT top.PROJECT_ID FROM APPLY_ORDER ao, tmp_overdue_projects top WHERE ao.APPLY_NO = top.PROJECT_ID AND ao.NO_SETT_PERIOD =0 AND ao.END_DATE <=@EXPORT_DATE);

-- 更新本次上报项目的最后一次上报时间为当前
UPDATE tmp_overdue_repo
	SET last_date = @EXPORT_DATE
	WHERE PROJECT_ID in (SELECT PROJECT_ID from tmp_overdue_projects);


-- 上报历史数据
INSERT INTO t_his_credit
	(ProjectID, Peroid, over_day_count, FINORGCODE, LOANTYPE, 
	LOANBIZTYPE, BUSINESS_NO, AREACODE, STARTDATE, ENDDATE, 
	CURRENCY, CREDIT_TOTAL_AMT, SHARE_CREDIT_TOTAL_AMT, MAX_DEBT_AMT, GUARANTEEFORM, 
	PAYMENT_RATE, PAYMENT_MONTHS, NO_PAYMENT_MONTHS, PLAN_REPAY_DT, LAST_REPAY_DT, 
	PLAN_REPAY_AMT, LAST_REPAY_AMT, BALANCE, CUR_OVERDUE_TOTAL_INT, CUR_OVERDUE_TOTAL_AMT, 
	OVERDUE31_60DAYS_AMT, OVERDUE61_90DAYS_AMT, OVERDUE91_180DAYS_AMT, OVERDUE_180DAYS_AMT, SUM_OVERDUE_INT, 
	MAX_OVERDUE_INT, CLASSIFY5, LOAN_STAT, REPAY_MONTH_24_STAT, OVERDRAFT_180DAYS_BAL, 
	LOAN_ACCOUNT_STAT, CUSTNAME, CERTTYPE, CERTNO, CUSTID, 
	BAKE)
	select ProjectID, Peroid, over_day_count, FINORGCODE, LOANTYPE, 
		LOANBIZTYPE, BUSINESS_NO, AREACODE, STARTDATE, ENDDATE, 
		CURRENCY, CREDIT_TOTAL_AMT, SHARE_CREDIT_TOTAL_AMT, MAX_DEBT_AMT, GUARANTEEFORM, 
		PAYMENT_RATE, PAYMENT_MONTHS, NO_PAYMENT_MONTHS, PLAN_REPAY_DT, LAST_REPAY_DT, 
		PLAN_REPAY_AMT, LAST_REPAY_AMT, BALANCE, CUR_OVERDUE_TOTAL_INT, CUR_OVERDUE_TOTAL_AMT, 
		OVERDUE31_60DAYS_AMT, OVERDUE61_90DAYS_AMT, OVERDUE91_180DAYS_AMT, OVERDUE_180DAYS_AMT, SUM_OVERDUE_INT, 
		MAX_OVERDUE_INT, CLASSIFY5, LOAN_STAT, REPAY_MONTH_24_STAT, OVERDRAFT_180DAYS_BAL, 
		LOAN_ACCOUNT_STAT, CUSTNAME, CERTTYPE, CERTNO, CUSTID, 
		BAKE FROM tmp_overdue
		where (ProjectID , PLAN_REPAY_DT ) NOT IN (SELECT ProjectID , PLAN_REPAY_DT FROM t_his_credit  );

-- 特殊交易历史数据
INSERT INTO t_his_credit_spec
(BUSINESS_NO, FINORGCODE, SPEC_EVENT_CD, OCCURDATE, EXTENT_MONTHS, EVENT_AMT, EVENT_DTL)
	SELECT BUSINESS_NO, FINORGCODE, SPEC_EVENT_CD, OCCURDATE, EXTENT_MONTHS, EVENT_AMT, EVENT_DTL
	FROM V_CREDIT_SPEC_EVENT ;

	
END