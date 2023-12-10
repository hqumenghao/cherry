--统计日期
declare @stockDate varchar(10)
-- 统计日期的上个月
declare @lastMonth varchar(10)

set @stockDate = '2022-10-25'
SELECT @lastMonth = CONVERT(varchar(10), CONVERT(varchar(8),dateadd(month,-1,@stockDate),120)+'25' , 120)

delete from [Inventory].[BIN_ProStockHistory] where CutOfDate=@stockDate


INSERT INTO [Inventory].[BIN_ProStockHistory]
           ([BIN_OrganizationInfoID]
           ,[BIN_BrandInfoID]
           ,[BIN_ProductVendorID]
           ,[BIN_InventoryInfoID]
           ,[BIN_LogicInventoryInfoID]
           ,[BIN_StorageLocationInfoID]
           ,[Quantity]
           ,[Amount]
           ,[BIN_ProductVendorPackageID]
           ,[CutOfDate]
           ,[RepeatCount]
           ,[ValidFlag]
           ,[CreateTime]
           ,[CreatedBy]
           ,[CreatePGM]
           ,[UpdateTime]
           ,[UpdatedBy]
           ,[UpdatePGM]
           ,[ModifyCount]
           ,[AssistQuantity])
select 1 as BIN_OrganizationInfoID,1 as BIN_BrandInfoID,C.BIN_ProductVendorID,C.BIN_InventoryInfoID
           ,C.BIN_LogicInventoryInfoID
           ,'0' as BIN_StorageLocationInfoID
           ,isnull(C.Quantity,0)-
           isnull(sum(case when isnull(T0.StockType,'0')='0' 
           then isnull(T0.Quantity,0) else 0-isnull(T0.quantity,0) end),0) as quantity
           ,0 as Amount
           ,0 as BIN_ProductVendorPackageID
           ,@stockDate as CutOfDate
           ,0 as RepeatCount
           ,1 as ValidFlag
           ,GETDATE() as CreateTime
           ,'script' as CreatedBy
           ,'script' as CreatePGM
           ,GETDATE() as UpdateTime
           ,'script' as UpdatedBy
           ,'script' as UpdatePGM
           ,0 as ModifyCount
           ,0 as AssistQuantity
    from 
    Inventory.BIN_ProductStock C 
    left join (
select B.* from  
Inventory.BIN_ProductInOutDetail B
join Inventory.BIN_ProductInOut C
on  B.BIN_ProductInOutID=C.BIN_ProductInOutID
and C.StockInOutDate>@stockDate
) T0  on C.BIN_InventoryInfoID=T0.BIN_InventoryInfoID
and C.BIN_LogicInventoryInfoID=T0.BIN_LogicInventoryInfoID
and C.BIN_ProductVendorID=T0.BIN_ProductVendorID
group by 
C.BIN_InventoryInfoID,
C.BIN_LogicInventoryInfoID,
C.BIN_ProductVendorID,
C.Quantity
having isnull(C.Quantity,0)-isnull(sum(case when isnull(T0.StockType,'0')='0' then isnull(T0.Quantity,0) else 0-isnull(T0.quantity,0) end),0)<>0


update 
Inventory.bin_productinout
set CloseFlag='1'
 where StockInOutDate>@lastMonth
and StockInOutDate<=@stockDate
and closeFlag='0'


go

