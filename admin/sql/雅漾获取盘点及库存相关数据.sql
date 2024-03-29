declare @startDate varchar(30)
declare @salepriceDate varchar(30)
declare @endDate varchar(30)
set @startDate= '2023-12-01'
set @salepriceDate = '2023-12-31'
set @endDate = '2023-12-31'
 
-- 用当前库存反推出期初库存
select
    org.type,
    region.RegionNameChinese as regionName,
    city.RegionNameChinese as cityName,
    org.BIN_OrganizationID,
    org.DepartCode,org.DepartName,
    pv.UnitCode,pv.BarCode,pv.NameTotal,
    C.BIN_InventoryInfoID,
    C.BIN_LogicInventoryInfoID,
    C.BIN_ProductVendorID
    ,isnull(C.Quantity,0)-
    isnull(sum(case when isnull(T0.StockType,'0')='0'
    then isnull(T0.Quantity,0) else 0-isnull(T0.quantity,0) end),0) as quantity
    , @startDate as stockDate
into #productStockStart
from
    Inventory.BIN_ProductStock C
    left join (
        select B.* from
        Inventory.BIN_ProductInOutDetail B
        join Inventory.BIN_ProductInOut C
        on  B.BIN_ProductInOutID=C.BIN_ProductInOutID
        and C.StockInOutDate>=@startDate
    ) T0  on C.BIN_InventoryInfoID=T0.BIN_InventoryInfoID
    and C.BIN_LogicInventoryInfoID=T0.BIN_LogicInventoryInfoID
    and C.BIN_ProductVendorID=T0.BIN_ProductVendorID
    left join basis.BIN_InventoryInfo inv
    on C.BIN_InventoryInfoID=inv.BIN_InventoryInfoID
    left join basis.BIN_Organization org
    on inv.BIN_OrganizationID=org.BIN_OrganizationID
    left join basis.BIN_Region region
    on org.BIN_RegionID=region.BIN_RegionID
    left join basis.BIN_Region city
    on org.BIN_CityID=city.BIN_RegionID
    join basis.BIN_ProductVendor pv
    on C.BIN_ProductVendorID=pv.BIN_ProductVendorID
    --and pv.ValidFlag='1' and pv.IsStock='1'
    join Basis.SalePriceDepartProductDetail spdp
    on C.BIN_InventoryInfoID=spdp.BIN_InventoryInfoID
    and C.BIN_ProductVendorID=spdp.BIN_ProductVendorId
    and  @salepriceDate between StartDate and EndDate
where
    org.Type in('4','3') and org.TestType='0'
group by
    org.type,
    region.RegionNameChinese,
    city.RegionNameChinese,
    org.BIN_OrganizationID,
    org.DepartCode,org.DepartName,
    pv.UnitCode,pv.BarCode,pv.NameTotal,
    C.BIN_InventoryInfoID,
    C.BIN_LogicInventoryInfoID,
    C.BIN_ProductVendorID,
    C.Quantity
 
-- 期末库存
select
    org.type,
    region.RegionNameChinese as regionName,
    city.RegionNameChinese as cityName,
    org.BIN_OrganizationID,
    org.DepartCode,org.DepartName,
    pv.UnitCode,pv.BarCode,pv.NameTotal,
    C.BIN_InventoryInfoID,
    C.BIN_LogicInventoryInfoID,
    C.BIN_ProductVendorID
    ,isnull(C.Quantity,0)-
    isnull(sum(case when isnull(T0.StockType,'0')='0'
    then isnull(T0.Quantity,0) else 0-isnull(T0.quantity,0) end),0) as quantity
    , @endDate as stockDate
into #productStockEnd
from
    Inventory.BIN_ProductStock C
    left join (
        select B.* from
        Inventory.BIN_ProductInOutDetail B
        join Inventory.BIN_ProductInOut C
        on  B.BIN_ProductInOutID=C.BIN_ProductInOutID
        and C.StockInOutDate>@endDate
    ) T0  on C.BIN_InventoryInfoID=T0.BIN_InventoryInfoID
    and C.BIN_LogicInventoryInfoID=T0.BIN_LogicInventoryInfoID
    and C.BIN_ProductVendorID=T0.BIN_ProductVendorID
    left join basis.BIN_InventoryInfo inv
    on C.BIN_InventoryInfoID=inv.BIN_InventoryInfoID
    left join basis.BIN_Organization org
    on inv.BIN_OrganizationID=org.BIN_OrganizationID
    left join basis.BIN_Region region
    on org.BIN_RegionID=region.BIN_RegionID
    left join basis.BIN_Region city
    on org.BIN_CityID=city.BIN_RegionID
    join basis.BIN_ProductVendor pv
    on C.BIN_ProductVendorID=pv.BIN_ProductVendorID
    --and pv.ValidFlag='1' and pv.IsStock='1'
    join Basis.SalePriceDepartProductDetail spdp
    on C.BIN_InventoryInfoID=spdp.BIN_InventoryInfoID
    and C.BIN_ProductVendorID=spdp.BIN_ProductVendorId
    and  @salepriceDate between StartDate and EndDate
where
    org.Type in('4','3') and org.TestType='0'
group by
    org.type,
    region.RegionNameChinese,
    city.RegionNameChinese,
    org.BIN_OrganizationID,
    org.DepartCode,org.DepartName,
    pv.UnitCode,pv.BarCode,pv.NameTotal,
    C.BIN_InventoryInfoID,
    C.BIN_LogicInventoryInfoID,
    C.BIN_ProductVendorID,
    C.Quantity
     
-- 所有经销商及柜台的23年7月后的第一次盘点的实盘数及账面数
select
    A.StockTakingNoIF,convert(datetime,convert(varchar,A.date)+' '+A.TradeTime) as stocktakingDatetime,
    B.BIN_InventoryInfoID,B.BIN_LogicInventoryInfoID,B.BIN_ProductVendorID,
    B.Quantity+B.GainQuantity as firstCheckQuantity,B.Quantity as firstbookQuantity
into #firstStockTaking
from
    Inventory.BIN_ProductStockTaking A
    join Inventory.BIN_ProductTakingDetail B
    on A.BIN_ProductStockTakingID=B.BIN_ProductTakingID
    join basis.BIN_Organization org
    on A.BIN_OrganizationID=org.BIN_OrganizationID
    and org.Type in('3','4')  and org.TestType='0'
    join basis.BIN_ProductVendor pv
    on B.BIN_ProductVendorID=pv.BIN_ProductVendorID and pv.IsStock='1'
where A.Date>= @startDate
    and not exists(
        select 1 from
            Inventory.BIN_ProductStockTaking lt
            join Inventory.BIN_ProductTakingDetail ltd
            on lt.BIN_ProductStockTakingID=ltd.BIN_ProductTakingID
        where 
            A.BIN_OrganizationID=lt.BIN_OrganizationID
            and B.BIN_ProductVendorID=ltd.BIN_ProductVendorID
            and lt.Date>= @startDate and ltd.CreateTime<B.CreateTime
    )
     
     
-- 所有经销商及柜台的23年7月后的最后一次盘点的实盘数及账面数
select A.StockTakingNoIF,convert(datetime,convert(varchar,A.date)+' '+A.TradeTime) as stocktakingDatetime,B.BIN_InventoryInfoID,B.BIN_LogicInventoryInfoID,B.BIN_ProductVendorID,
B.Quantity+B.GainQuantity as lastCheckQuantity,B.Quantity as lastbookQuantity
into #lastStockTaking
 from Inventory.BIN_ProductStockTaking A
join Inventory.BIN_ProductTakingDetail B
on A.BIN_ProductStockTakingID=B.BIN_ProductTakingID
join basis.BIN_Organization org
on A.BIN_OrganizationID=org.BIN_OrganizationID
and org.Type in('3','4')  and org.TestType='0'
join basis.BIN_ProductVendor pv
on B.BIN_ProductVendorID=pv.BIN_ProductVendorID and pv.IsStock='1'
where A.Date>= @startDate
and not exists(
select 1 from Inventory.BIN_ProductStockTaking lt
join Inventory.BIN_ProductTakingDetail ltd
on lt.BIN_ProductStockTakingID=ltd.BIN_ProductTakingID
where  A.BIN_OrganizationID=lt.BIN_OrganizationID
and B.BIN_ProductVendorID=ltd.BIN_ProductVendorID
and lt.Date>= @startDate and ltd.CreateTime>B.CreateTime
)
     
     
-- 所有经销商及柜台的23年7月后的所有盘点单的盘盈数汇总、盘点亏数汇总
select --A.StockTakingNoIF,convert(datetime,convert(varchar,A.date)+' '+A.TradeTime) as stocktakingDatetime,
B.BIN_InventoryInfoID,
B.BIN_LogicInventoryInfoID,
B.BIN_ProductVendorID,
sum(case when B.GainQuantity>0 then B.GainQuantity else 0 end) as addQuantity,
sum(case when B.GainQuantity<0 then B.GainQuantity else 0 end) as subQuantity
into #StockTakingGainInfo
 from Inventory.BIN_ProductStockTaking A
join Inventory.BIN_ProductTakingDetail B
on A.BIN_ProductStockTakingID=B.BIN_ProductTakingID
join basis.BIN_Organization org
on A.BIN_OrganizationID=org.BIN_OrganizationID
and org.Type in('3','4')  and org.TestType='0'
join basis.BIN_ProductVendor pv
on B.BIN_ProductVendorID=pv.BIN_ProductVendorID and pv.IsStock='1'
where A.Date>= @startDate
group by B.BIN_InventoryInfoID,
B.BIN_LogicInventoryInfoID,
B.BIN_ProductVendorID
     
-- 最后一次盘点至结束日期的入出库汇总记录,排除盘点业务数据
select A.BIN_InventoryInfoID,
A.BIN_LogicInventoryInfoID,A.BIN_ProductVendorID,
sum(case when isnull(A.StockType,'0')='0' then isnull(A.Quantity,0) else 0 end ) as inQuantity,
sum(case when isnull(A.StockType,'0')='1' then isnull(A.Quantity,0) else 0 end ) as outQuantity
into  #stockInOutDetail
from Inventory.BIN_ProductInOutDetail A
left join #lastStockTaking B
on A.BIN_InventoryInfoID=B.BIN_InventoryInfoID
and A.BIN_LogicInventoryInfoID=B.BIN_LogicInventoryInfoID
and A.BIN_ProductVendorID=B.BIN_ProductVendorID
left join Inventory.BIN_ProductInOut C
on A.BIN_ProductInOutID=C.BIN_ProductInOutID
and isnull(B.stocktakingDatetime,@startDate)<C.StockInOutTime
where C.StockInOutDate between @startDate and @endDate
and C.TradeType<>'CA'
group by A.BIN_InventoryInfoID,
A.BIN_LogicInventoryInfoID,A.BIN_ProductVendorID
     
--近90天内已发货未收货的在途库存
--最后一次盘点后发货的订单，但是在12.31日未收货的订单
SELECT
            A.BIN_OrganizationIDReceive,
            C.BIN_InventoryInfoID,
            B.BIN_ProductVendorID,
            2 as BIN_LogicInventoryInfoID,
            sum(B.Quantity) as onDeliveryStock
into  #onDeliveryStock
        FROM
            Inventory.BIN_ProductDeliver A WITH(NOLOCK)
            join Inventory.BIN_ProductDeliverDetail B WITH(NOLOCK)
            on A.BIN_ProductDeliverID=b.BIN_ProductDeliverID
            left join basis.BIN_InventoryInfo C WITH(NOLOCK)
            on A.BIN_OrganizationIDReceive=C.BIN_OrganizationID
        WHERE
             A.Date between @startDate and @endDate
            and (A.tradeStatus='12' or (A.tradeStatus='13' and  exists(select 1 from Inventory.BIN_ProductReceive PR with(nolock)
            where A.DeliverNoIF=PR.RelevanceNo
            and PR.ReceiveDate>@endDate--@salepriceDate
            )))
            and exists(
            select 1 from  #lastStockTaking ST
            where  C.BIN_InventoryInfoID=ST.BIN_InventoryInfoID
            and A.CreateTime>isnull(ST.stocktakingDatetime,@startDate)
            )
        GROUP BY
            A.BIN_OrganizationIDReceive,
            C.BIN_InventoryInfoID,
            B.BIN_ProductVendorID
 
 
         
     
     
-- 按模板汇总出数据(柜台)
select
A.regionName as '区域',A.cityname as '城市',
reseller.DepartName as '经销商部门',cha.ChannelName as '渠道',
A.departCode as '柜台号',A.departName as '柜台名称',
big.PropValueChinese as '大分类',
mid.PropValueChinese as '中分类',
small.PropValueChinese as '小分类',
PUID.PropValueChinese as '产品合并英文名',
A.unitcode as '厂商编码',A.barcode as '产品条码',A.NameTotal as '产品名称',isnull(F.SalePrice,0) as '价格',
isnull(FS.firstbookQuantity,A.quantity) as '盘点前库存',
B.lastCheckQuantity '最后一次盘点实盘数',
---- C.addQuantity as '盘盈',C.subQuantity as '盘亏',
isnull(B.lastCheckQuantity,0)-isnull(FS.firstbookQuantity,0) as '盘差',
isnull(D.inQuantity,0) as '入库',
isnull(D.outQuantity,0) as '出库',
isnull(C.onDeliveryStock,0) as '在途库存',
isnull(ED.quantity,0) as '期末库存'
into [manualdata].dbo.CounterProductStockTemp
from #productStockStart A
left join #productStockEnd ED
on A.[BIN_InventoryInfoID]=ED.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=ED.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=ED.[BIN_ProductVendorID]
left join #firstStockTaking FS
on A.[BIN_InventoryInfoID]=FS.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=FS.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=FS.[BIN_ProductVendorID]
left join #lastStockTaking B
on A.[BIN_InventoryInfoID]=B.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=B.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=B.[BIN_ProductVendorID]
-- left join #StockTakingGainInfo C
-- on A.[BIN_InventoryInfoID]=C.[BIN_InventoryInfoID]
-- and A.[BIN_LogicInventoryInfoID]=C.[BIN_LogicInventoryInfoID]
-- and A.[BIN_ProductVendorID]=C.[BIN_ProductVendorID]
left join #onDeliveryStock C
on A.[BIN_InventoryInfoID]=C.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=C.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=C.[BIN_ProductVendorID]
left join #stockInOutDetail D
on A.[BIN_InventoryInfoID]=D.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=D.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=D.[BIN_ProductVendorID]
left join basis.BIN_CounterInfo cnt
on A.BIN_OrganizationID=cnt.BIN_OrganizationID
left join basis.BIN_Organization reseller
on cnt.resellerDepartId=reseller.BIN_OrganizationID
left join basis.BIN_Channel cha
on cnt.SecondChannelID=cha.BIN_ChannelID
left join basis.BIN_ProductVendor pv
on pv.BIN_ProductVendorID=A.BIN_ProductVendorID
left join Basis.BIN_PrtCatPropValue big
on big.BIN_PrtCatPropValueID=pv.CategoryID1
left join Basis.BIN_PrtCatPropValue mid
on mid.BIN_PrtCatPropValueID=pv.CategoryID3
left join Basis.BIN_PrtCatPropValue small
on small.BIN_PrtCatPropValueID=pv.CategoryID2
left join Basis.BIN_PrtCatPropValue PUID
on pv.CategoryID5=PUID.BIN_PrtCatPropValueID
LEFT JOIN Basis.BIN_ProductPrice F WITH(NOLOCK)
ON (pv.BIN_ProductVendorID = F.BIN_ProductID AND F.Type = '2' AND GETDATE() BETWEEN F.StartDate AND F.EndDate AND F.ValidFlag = '1')
where A.type='4'
-- and B.lastCheckQuantity is not null
 
-- 按模板汇总出数据(经销商)
select
A.regionName as '区域',A.cityname as '城市',
A.departCode as '部门code',A.departName as '部门名称',
big.PropValueChinese as '大分类',
mid.PropValueChinese as '中分类',
small.PropValueChinese as '小分类',
PUID.PropValueChinese as '产品合并英文名',
A.unitcode as '厂商编码',A.barcode as '产品条码',A.NameTotal as '产品名称',isnull(F.SalePrice,0) as '价格',
-- isnull(A.quantity,0) as '期初库存',
isnull(FS.firstbookQuantity,A.quantity) as '盘点前库存',
B.lastCheckQuantity '最后一次盘点实盘数',
-- C.addQuantity as '盘盈',C.subQuantity as '盘亏',
isnull(B.lastCheckQuantity,0)-isnull(FS.firstbookQuantity,0) as '盘差',
isnull(D.inQuantity,0) as '入库',
isnull(D.outQuantity,0) as '出库',
isnull(C.onDeliveryStock,0) as '在途库存',
isnull(ED.quantity,0) as '期末库存'
into [ManualData].dbo.resellerProductStockTemp
from #productStockStart A
left join #productStockEnd ED
on A.[BIN_InventoryInfoID]=ED.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=ED.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=ED.[BIN_ProductVendorID]
left join #firstStockTaking FS
on  A.[BIN_InventoryInfoID]=FS.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=FS.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=FS.[BIN_ProductVendorID]
left join #lastStockTaking B
on A.[BIN_InventoryInfoID]=B.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=B.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=B.[BIN_ProductVendorID]
-- left join #StockTakingGainInfo C
-- on A.[BIN_InventoryInfoID]=C.[BIN_InventoryInfoID]
-- and A.[BIN_LogicInventoryInfoID]=C.[BIN_LogicInventoryInfoID]
-- and A.[BIN_ProductVendorID]=C.[BIN_ProductVendorID]
left join #onDeliveryStock C
on A.[BIN_InventoryInfoID]=C.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=C.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=C.[BIN_ProductVendorID]
left join #stockInOutDetail D
on A.[BIN_InventoryInfoID]=D.[BIN_InventoryInfoID]
and A.[BIN_LogicInventoryInfoID]=D.[BIN_LogicInventoryInfoID]
and A.[BIN_ProductVendorID]=D.[BIN_ProductVendorID]
left join basis.BIN_Organization org
on A.BIN_OrganizationID=org.BIN_OrganizationID
left join basis.BIN_ProductVendor pv
on pv.BIN_ProductVendorID=A.BIN_ProductVendorID
left join Basis.BIN_PrtCatPropValue big
on big.BIN_PrtCatPropValueID=pv.CategoryID1
left join Basis.BIN_PrtCatPropValue mid
on mid.BIN_PrtCatPropValueID=pv.CategoryID3
left join Basis.BIN_PrtCatPropValue small
on small.BIN_PrtCatPropValueID=pv.CategoryID2
left join Basis.BIN_PrtCatPropValue PUID
on pv.CategoryID5=PUID.BIN_PrtCatPropValueID
LEFT JOIN Basis.BIN_ProductPrice F WITH(NOLOCK)
ON (pv.BIN_ProductVendorID = F.BIN_ProductID AND F.Type = '2' AND GETDATE() BETWEEN F.StartDate AND F.EndDate AND F.ValidFlag = '1')
where A.type='3'
-- and B.lastCheckQuantity is not null


select A.*,case when A.[盘差]>=0 then A.[盘差] else 0 end as '盘盈',
case when A.[盘差]<0 then A.[盘差] else 0 end as '盘亏',
case when B.ValidFlag='1' then  '启用' else '停用' end as '部门有效区分',
case when pv.ValidFlag='1' then  '启用' else '停用' end as '产品有效区分',
case when C.SalePriceDepartProductDetailID is not null then '是' else '否' end as '是否价目表'
  from [ManualData].dbo.resellerProductStockTemp A
left join basis.BIN_Organization B
on B.DepartCode=A.[部门code]
left join basis.BIN_ProductVendor pv
on pv.UnitCode=A.[厂商编码] and pv.BarCode=A.[产品条码]
left join [Basis].[SalePriceDepartProductDetail] C
on B.BIN_OrganizationID=C.BIN_OrganizationId
and pv.BIN_ProductVendorID=C.BIN_ProductVendorId
and ('2023-12-31' between C.StartDate and C.EndDate)
order by A.[部门code],A.[厂商编码],A.[产品条码]
 
select A.*,
case when A.[盘差]>=0 then A.[盘差] else 0 end as '盘盈',
case when A.[盘差]<0 then A.[盘差] else 0 end as '盘亏',
case when B.ValidFlag='1' then  '启用' else '停用' end as '部门有效区分',
case when pv.ValidFlag='1' then  '启用' else '停用' end as '产品有效区分',
case when C.SalePriceDepartProductDetailID is not null then '是' else '否' end as '是否价目表'
 from [manualdata].dbo.CounterProductStockTemp A
left join basis.BIN_Organization B
on B.DepartCode=A.[柜台号]
left join basis.BIN_ProductVendor pv
on pv.UnitCode=A.[厂商编码] and pv.BarCode=A.[产品条码]
left join [Basis].[SalePriceDepartProductDetail] C
on B.BIN_OrganizationID=C.BIN_OrganizationId
and pv.BIN_ProductVendorID=C.BIN_ProductVendorId
and ('2023-12-31' between C.StartDate and C.EndDate)
order by A.[柜台号],A.[厂商编码],A.[产品条码]