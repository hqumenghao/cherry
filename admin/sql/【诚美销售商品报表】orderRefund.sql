select
    year(a.createdOn) as createdOnYear,
    month(a.createdOn) as createdOnMonth,
    day(a.createdOn) as createdOnDay,
    a.createdOn as createdOn,
    a.DocNo as DocNo,
    case when OriginType='BUYER_ORDERING' then '销售单'
    when OriginType='REISSUE_ORDER' then '补发订单'
    when OriginType='ExCHANGE_ORDER' then '换货订单'
    end as OriginType,
    DN.distributionNo as distributionNo,
    DTC.DeliveryThirdDocCode as deliveryThirdDocCode,
    concat('[',b.parentCode,']',b.parentName) as parentName,
    orgCate.name as orgCateName,
    org.oid as orgId,
    concat('[',org.code,']',org.name) as orgName,
    case when DocStatus='WAIT_DELIVER' then '待发货'
    when DocStatus='DELIVER_ON' then '发货中'
    when DocStatus='DELIVER_END' then '发货完成'
    when DocStatus='TRADING_END' then '交易完成'
    end as DocStatus,
    case when c.ItemStatus='WAIT_DELIVER' then '待发货'
    when c.ItemStatus='DELIVER_ALL' then '已发货'
    when c.ItemStatus='DELIVER_PART' then '部分发货'
    when c.ItemStatus='DELIVER_PART_CANCELED' then '部分发货剩余取消'
    when c.ItemStatus='RECEIVED_PART_CANCELED' then '部分收货剩余取消'
    when c.ItemStatus='RECEIVED_ALL' then '已收货'
    when c.ItemStatus='CANCELED' then '已取消'
    end as ItemDeliveryStatus,
    f.name as brandName,
    d.code as unitCode,
    d.barcode as barcode,
    d.name as productName, 
    case when e.productType='normal' then '普通商品'
    when e.productType='promotion' then '促销品'
    when e.productType='storedValueCard' then '储值卡'
    when e.productType='service' then '服务'
    when e.productType='pkgmaterial' then '包材'
    when e.productType='material' then '物料'
    when e.productType='sample' then '试用装'
    when e.productType='benefitCard' then '权益卡'
    when e.productType='repair' then '道具'
    when e.productType='coupon' then '优惠券'
    when e.productType='giftCard' then '礼品卡'
    end as productType,
    case when c.SaleType='SALE' then '销售'
    when c.SaleType='GIVE' then '赠送'
    when c.SaleType='Verification' then '核销'
    end as SaleType,
    c.SalePrice,
    c.Price,
    c.DiscountRate,
    c.Quantity,
    case when OriginType='BUYER_ORDERING' then c.PaymentAmount else 0 end as PaymentAmount,
    c.DeliveredQuantity,
    c.UnDeliveredQuantity
from salesorder a
left join (
    select  
        distinct SalesOrderId,GROUP_CONCAT(distinct B.docNo SEPARATOR ',') as distributionNo
    from 
        SCMDistributionMainItem A
        join SCMDistributionMain B
        on A.parentId=B.oid
    where
        B.Status<>'Cancel' 
    group by SalesOrderId
) DN
on a.oid=DN.SalesOrderId
left join (
    select 
        distinct C.oid as SalesOrderId,GROUP_CONCAT(distinct B.thirdDocCode SEPARATOR ',') as DeliveryThirdDocCode 
    from 
        DeliveryOrderItem A
        join DeliveryOrder B
        on A.parentId=B.oid
        join salesorder C
        on A.SalesOrder=C.oid
    group by C.oid
) DTC
on a.oid=DTC.SalesOrderId
left join (
    select a.parentid as orgid,B.code as parentCode,b.name as parentName
    from bscbusinessorganization a
    left join bscbusinessorganization b
    on a.parentBusinessOrgId =b.oid and a.orgBusinessTypeId=b.orgBusinessTypeId
    where a.orgBusinessTypeId in(select oid from nbscbscorgbusinesstype where code ='ADMIN')
) b on a.OrderOrgId=b.orgid
left join BscOrganization org
on a.OrderOrgId=org.oid
left join BscOrganizationCategory orgCate
on org.organizationCategoryId=orgCate.oid
left join salesorderitem c
on a.oid=c.parentid
left join bscproductsku d
on c.ProductSkuId=d.oid
left join BscProduct e
on d.parentid=e.oid
left join BscProductBrand f
on e.productBrandId=f.oid
where a.OriginType in('BUYER_ORDERING','REISSUE_ORDER','ExCHANGE_ORDER')
and a.DocStatus in('WAIT_DELIVER','DELIVER_ON','DELIVER_END','TRADING_END')



union 
select 
    year(a.createdOn) as createdOnYear,
    month(a.createdOn) as createdOnMonth,
    day(a.createdOn) as createdOnDay,
    a.createdOn as createdOn,
    a.DocNo as DocNo,
    '退货单' as OriginType,
    '' as distributionNo,
    DTC.DeliveryThirdDocCode as deliveryThirdDocCode,
    concat('[',b.parentCode,']',b.parentName) as parentName,
    orgCate.name as orgCateName,
    org.oid as orgId,
    concat('[',org.code,']',org.name) as orgName,
    case when a.DocStatus='WAIT_WAREHOUSE_CONFIRM_GOODS' then '仓库收货中'
    when a.DocStatus='REFUNDFEE_FINASH' then '已完成'
    end as DocStatus,
    '' as ItemDeliveryStatus,
    f.name as brandName,
    d.code as unitCode,
    d.barcode as barcode,
    d.name as productName,
    case when e.productType='normal' then '普通商品'
    when e.productType='promotion' then '促销品'
    when e.productType='storedValueCard' then '储值卡'
    when e.productType='service' then '服务'
    when e.productType='pkgmaterial' then '包材'
    when e.productType='material' then '物料'
    when e.productType='sample' then '试用装'
    when e.productType='benefitCard' then '权益卡'
    when e.productType='repair' then '道具'
    when e.productType='coupon' then '优惠券'
    when e.productType='giftCard' then '礼品卡'
    end as productType,
    case when orderItem.SaleType='SALE' then '销售'
    when orderItem.SaleType='GIVE' then '赠送'
    when orderItem.SaleType='Verification' then '核销'
    end as SaleType,
    orderItem.SalePrice,
    orderItem.Price,
    orderItem.DiscountRate,
    c.RefundQuantity  as Quantity,
    0 as PaymentAmount,
    null DeliveredQuantity,
    null UnDeliveredQuantity
from RefundOrder a
left join (
    select 
        R.oid as refundOrderId,
        GROUP_CONCAT(distinct C.DocNo SEPARATOR ',') as deliverNo,
        GROUP_CONCAT(distinct C.thirdDocCode SEPARATOR ',') as DeliveryThirdDocCode
    from 
        ScmSwapOutSku B
        join refundOrder R
        on B.relatedDocCode=R.relatedDocCode
        Left join DeliveryOrder C
        on B.relatedDocCode=C.DocNo
    group by R.oid
) DTC
on a.oid=DTC.refundOrderId
left join (
    select a.parentid as orgid,B.code as parentCode,b.name as parentName
    from bscbusinessorganization a
    left join bscbusinessorganization b
    on a.parentBusinessOrgId =b.oid and a.orgBusinessTypeId=b.orgBusinessTypeId
    where a.orgBusinessTypeId in(select oid from nbscbscorgbusinesstype where code ='ADMIN')
) b on a.RefundOrgId=b.orgid
left join BscOrganization org
on a.RefundOrgId=org.oid
left join BscOrganizationCategory orgCate
on org.organizationCategoryId=orgCate.oid
left join RefundOrderItem c
on a.oid=c.parentid
left join ScmSwapOutSku swap
on c.RelatedDocItemId=swap.oid
left join DeliveryOrderItem deliverItem
on swap.relatedDocItemId=deliverItem.oid
left join SalesOrderItem orderItem
on deliverItem.SalesOrderItem=orderItem.oid
left join bscproductsku d
on c.ProductSkuId=d.oid
left join BscProduct e
on d.parentid=e.oid
left join BscProductBrand f
on e.productBrandId=f.oid
where a.DocStatus in('WAIT_WAREHOUSE_CONFIRM_GOODS','REFUNDFEE_FINASH')