# 项目介绍
    本项目主要实现的有两个部分：代理合约部分、策略合约部分

### uniswapv3-proxy
这个智能合约是用来与uniswapv3做衔接交互，其中实现的功能函数有如下部分：
   - 1、swap
       币币交换功能，将 v3 中的 exactInputSingle 换币功能进行包装

   - 2、getPrice
       价格获取功能

   - 3、exactInputSingle
       v3 的原生换币功能

   - 4、_floor
       用来获取 tick 下限的计算功能
    
   - 5、_ceil
       用来获取 tick 上限的计算功能

   - 6、getPoolAddress
       获取 uniswapv3 交易所的流动性池子地址

   - 7、getPoolSlot
       获取流动性池子的相关详细信息
    
   - 8、getLiquidity
        获取池子当前流动性

   - 9、getAmountsForLiquidity
        获取币 A 、B 的量

   - 10、tickBitmap
        获取时间位图

   - 11、ticks
        获取所有 tick

   - 12、tickSpacing
        获取 tick 跨域度

   - 13、positions
        获取 NFT 相关信息

   - 14、mint
        添加流动性

   - 15、increaseLiquidity
        添加流动性

   - 16、decreaseLiquidity
        移除流动性

   - 17、collect
        缴纳手续费

### Strategy
    主要是实现策略相关的处理操作