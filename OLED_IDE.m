01 OLED驱动步骤
   01.选择驱动芯片时序
      本文选择8080并口时序
          #ifndef BSP_OLED_OLED_H_ （oled.h文件---有关宏定义）
          #define BSP_OLED_OLED_H_
          #include "main.h"         
          #define OLED_RS(x)       x ?  HAL_GPIO_WritePin(GPIOD, OLED_RS_Pin, GPIO_PIN_SET) : \
		                                HAL_GPIO_WritePin(GPIOD, OLED_RS_Pin, GPIO_PIN_RESET)
          #define OLED_RST(x)       x ?  HAL_GPIO_WritePin(OLED_RST_GPIO_Port, OLED_RST_Pin, GPIO_PIN_SET) : \
		                                HAL_GPIO_WritePin(OLED_RST_GPIO_Port, OLED_RST_Pin, GPIO_PIN_RESET)
          #define OLED_RD(x)       x ?  HAL_GPIO_WritePin(GPIOG, OLED_RD_Pin, GPIO_PIN_SET) : \
		                                HAL_GPIO_WritePin(GPIOG, OLED_RD_Pin, GPIO_PIN_SET)
          #define OLED_WR(x)       x ?  HAL_GPIO_WritePin(GPIOG, OLED_WR_Pin, GPIO_PIN_SET) : \
	          	                      HAL_GPIO_WritePin(GPIOG, OLED_WR_Pin, GPIO_PIN_SET)
          #define OLED_CS(x)       x ?  HAL_GPIO_WritePin(GPIOD, OLED_CS_Pin, GPIO_PIN_SET) : \
		                                HAL_GPIO_WritePin(GPIOD, OLED_CS_Pin, GPIO_PIN_RESET)
          #endif /* BSP_OLED_OLED_H_ */
          
          #include "oled.h"（oled.c文件内自定义8080时序输出函数）
          void oled_date_out(uint8_t date)                           //并口 8080 数据输出代码
          {
          	GPIOC->ODR = (GPIOC->ODR & 0XFF00) | (date & 0X00FF);    // 函数作用：把 8 位数据 date 输出到 GPIOC 低 8 位（PC0~PC7
          }                                                          // uint8_t date ：要写入 OLED 的8 位数据 / 命令（0~255）
                                                                     // ODR：输出数据寄存器（写这个寄存器就能控制 IO 口输出高低电平）
                                                                     // GPIOC->ODR：直接操作硬件寄存器（比 HAL 库更快，适合并口时序）
                                                                     // 0xFF00 = 二进制 1111 1111 0000 0000
                                                                     // & 按位与运算：把 GPIOC 的低 8 位 清零，高 8 位保持不变,目的：只改 PC0~PC7，不影响 PC8~PC15
                                                                     // 0x00FF = 二进制 0000 0000 1111 1111
                                                                     // 确保 date 只有低 8 位有效，防止数据异常
                                                                     // | 按位或运算,把清零后的高 8 位 + 新的 8 位数据 合并，写入 GPIOC->ODR
                                                                     注：有关与或非运算：
                                                                                      & 与 ：清零 ： 和0与 （破坏全1条件以置零）
                                                                                      | 或 ：置1  ： 和1或 （破坏无1条件以置1）
                                                                                      ~ 非 ：取反 ： 
                                                                                      口诀 ：与 0 清，或 1 置，与 1 或 0 都不变（与和或都有“保留”功能）
          void oled_wr_byte(uint8_t date,uint8_t cmd)                //cmd：决定写 命令 还是 数据 ， cmd = 0 → 写命令 ， cmd = 1 → 写数据
          {                                                          //时序
          	OLED_RS (cmd);        //数据类型，由传参决定               //         第一步：设置RS（命令/数据选择），先定是数据 / 命令       ：RS = 0 → 写命令，RS = 1 → 写数据
          	OLED_CS (0);          //拉低片选线，选中SSD1306            //         第二步：拉低片选CS，选中通讯芯片
          	OLED_WR (0);          //拉低WR线，准备数据                 //         第三步：拉低 写使能WR，准备写数据
          	oled_date_out(date);  //WR低电平期间，准备数据             //         第四步：把数据送到数据口 D0~D7
          	OLED_WR (1);          //在WR上升沿，数据发出               //         第五步：WR 上升沿 → 真正写入数据。8080 时序规则：WR 从 0 → 1 上升沿时，OLED 锁存数据
          	OLED_CS (1);          //取消片选                          //         第六步：取消片选
          	OLED_RS (1);          //释放RS线，恢复默认                 //         第七步：OLED 8080 接口的 默认空闲状态 = RS 高电平，不通信时，RS 保持 1（高）
                                                                                        要发命令时，才临时把 RS 拉 0，发完必须 恢复成 1，不然会影响下一次通信
          }
                                                                      //注：void oled_wr_byte)；作用：向 8080 并口 OLED 写入 1 个字节
                                                                            属于为了驱动 8080 并口 OLED 屏幕，自己定义写的底层函数
   02.初始化序列（厂家提供初始化序列，来源：芯片数据手册（Datasheet））
            void oled_init(void)
            {
	        	  oled_wr_byte(0xAE, OLED_CMD);   /* 关闭显示 */
	        	  oled_wr_byte(0xD5, OLED_CMD);   /* 设置时钟分频因子,震荡频率 */
	        	  oled_wr_byte(80, OLED_CMD);     /* [3:0],分频因子;[7:4],震荡频率 */
	        	  oled_wr_byte(0xA8, OLED_CMD);   /* 设置驱动路数 */
	       	    oled_wr_byte(0X3F, OLED_CMD);   /* 默认0X3F(1/64) */
	       	    oled_wr_byte(0xD3, OLED_CMD);   /* 设置显示偏移 */
	       	    oled_wr_byte(0X00, OLED_CMD);   /* 默认为0 */

	        	  oled_wr_byte(0x40, OLED_CMD);   /* 设置显示开始行 [5:0],行数. */

	        	  oled_wr_byte(0x8D, OLED_CMD);   /* 电荷泵设置 */
	        	  oled_wr_byte(0x14, OLED_CMD);   /* bit2，开启/关闭 */
	        	  oled_wr_byte(0x20, OLED_CMD);   /* 设置内存地址模式 */
	        	  oled_wr_byte(0x02, OLED_CMD);   /* [1:0],00，列地址模式;01，行地址模式;10,页地址模式;默认10; */
	        	  oled_wr_byte(0xA1, OLED_CMD);   /* 段重定义设置,bit0:0,0-&gt;0;1,0-&gt;127; */
	        	  oled_wr_byte(0xC8, OLED_CMD);   /* 设置COM扫描方向;bit3:0,普通模式;1,重定义模式 COM[N-1]-&gt;COM0;N:驱动路数 */
	        	  oled_wr_byte(0xDA, OLED_CMD);   /* 设置COM硬件引脚配置 */
	        	  oled_wr_byte(0x12, OLED_CMD);   /* [5:4]配置 */

	        	  oled_wr_byte(0x81, OLED_CMD);   /* 对比度设置 */
	        	  oled_wr_byte(0xEF, OLED_CMD);   /* 1~255;默认0X7F (亮度设置,越大越亮) */
	        	  oled_wr_byte(0xD9, OLED_CMD);   /* 设置预充电周期 */
	        	  oled_wr_byte(0xf1, OLED_CMD);   /* [3:0],PHASE 1;[7:4],PHASE 2; */
	        	  oled_wr_byte(0xDB, OLED_CMD);   /* 设置VCOMH 电压倍率 */
	        	  oled_wr_byte(0x30, OLED_CMD);   /* [6:4] 000,0.65*vcc;001,0.77*vcc;011,0.83*vcc; */

	        	  oled_wr_byte(0xA4, OLED_CMD);   /* 全局显示开启;bit0:1,开启;0,关闭;(白屏/黑屏) */
	        	  oled_wr_byte(0xA6, OLED_CMD);   /* 设置显示方式;bit0:1,反相显示;0,正常显示 */
	        	  oled_wr_byte(0xAF, OLED_CMD);   /* 开启显示 */
}
   03.测试OLED功能函数
              注意：以上我们在oled.c定义了很多函数
              1.void oled_date_out()； /并口 8080 数据输出函数
              2.void oled_wr_byte()；  /向 8080 并口OLED写入1个字节函数
              3.void oled_init()； /OLED初始化函数
              假设我们再定义一个函数测试我们的屏幕输出功能
              4.void oled_test()；功能实现函数

              其中真正实现功能的测试函数void oled_test()；
                                           |________________调用（/包含）1.void oled_date_out()；2.void oled_wr_byte()；等底层功能函数实现逻辑
              也就是说烧录程序时：main.c真用需要直接调用的就两个函数：
                                                                 3.void oled_init()； /OLED初始化函数
                                                                 4.void oled_test()；功能实现函数
              而 1.和 2.是被 3.调用的。
              所以 1.和 2.是 main.c 没有直接调用的函数，只要是间接调用（内部用），所以称为内部函数
              而 3.和 4.是main.c直接调用的，称为外部函数
              两种函数处理方式不同：
                                  直接函数：直接调用，需要 1.oled.c定义------>2.oled.h声明------->3.main.c调用（别忘了调用前#include../../BSP/OLED/oled.h)
                                  内部函数：间接调用，不需要三步走（定义-->声明-->调用），但是为了代码更安全、不冲突、规范
                                           企业习惯：只在内部用的函数必须加 static，变成内部私有函数：
                                                    static void oled_date_out(void)
                                                    {
                                                      //如是，定义时前面加static，加static好处：
                                                      1.只能在 oled.c 内部使用 2.外部文件无法调用，更安全 3.防止函数名冲突 4.编译器优化更好
                                                    }
              现在在oled.c定义一个测试函数：void oled_test()；
              实现功能：
                       void oled_test(void)                //三步定位法
                       {
                       	oled_wr_byte(0xB0,OLED_CMD);       // 0xB0 → 选择Page0（第0~7行像素）
                       	oled_wr_byte(0x00,OLED_CMD);       // 0x00 → 列地址低4位=0x0
                       	oled_wr_byte(0x10,OLED_CMD);       // 0x10 → 列地址高4位=0x1
                                                              组合结果：定位到第0页、第0列
                       	oled_wr_byte(0xFF,OLED_DATA);      // 0xFF（二进制11111111）表示该列的8个像素全部点亮
                                                              数据写入后，列地址自动+1，为连续写入做准备
                       }
                注：OLED_CMD与OLED_DATA定义在oled.h中：
                                                      #define OLED_CMD            0
                                                      #define OLED_DATA           1
                                                      代表RS位的高低电平（命令/数据），为了提升代码可读性做了宏定义
   04.点亮OLED的一个点

                 
              
                                                            
