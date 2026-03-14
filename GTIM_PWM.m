1.配置通用定时器（本实验选择TIM3）
  配置目录：
             1. Slave Mode(从模式)
             2. Trigger Source（触发源）
             3. Clock Source（时钟源）
             4. Channel1（通道1）
             5. Channel2（通道2）
             6. Channel3（通道3）
             7. Channel4（通道4）
             8. Combined Channels（组合通道）
             9. Use ETR as Clearing Source（用 ETR 信号作为计数器清零源）
             10.XOR activation（启用通道输入异或功能，常用于编码器接口）
             11.One Pulse Mode（单脉冲模式）
 目录展开：
             1. Slave Mode(从模式)
                                                                          核心行为                                                   典型例子                                  触发源选择                                
                  01 Disable（禁用）                           不受外部触发控制，按内部时钟自由计数                   （独立跑）普通延时、PWM 输出、自由运行计时                 无需触发源
                  02 External Clock Mode 1（外部时钟模式 1）   用 TRGI 信号作为计数时钟，单边沿计数                   （数脉冲）计数传感器脉冲、简单转速测量                     TI1_ED / ETRF
                  03 Reset Mode（复位模式）                    收到 TRGI 边沿时，计数器清零并重启                     （触发归零）每触发一次就重新计时（如门禁开门计时）         TI1FP1 / TI2FP2 / ETRF
                  04 Gated Mode（门控模式）                    TRGI 高电平计数、低电平暂停                            （高电平才计）测量高电平持续时间、使能信号控制计数         TI1FP1 / TI2FP2
                  05 Trigger Mode（触发模式）                  收到 TRGI 边沿时启动 / 重启计数器，之后自由运行        （触发就开始）按键后开始计时、外部信号同步启动采样         TI1_ED / ETRF / ITRx
            
             2. Trigger Source（触发源）
                    触发源就是给定时器 “发信号” 的源头，是能让定时器做出特定动作（启动、停止、清零、计数）的外部 / 内部信号。
                  01 ITR0    内部触发输入0
                  02 ITR1    内部触发输入1
                  03 ITR2    内部触发输入2
                  04 ITR3    内部触发输入3
                  05 ETR1    外部触发输入1
                  06 TI1-ED  TI1边沿检测器
                  07 TI1FP1  TI1滤波后极性选择信号1
                  08 TI2FP2  TI2滤波后极性选择信号2
                    触发源选择的本质是回答两个问题：
                        a.信号从哪来？（引脚 / 内部定时器 / 其他模块）
                        b.要实现什么功能？（启动 / 复位 / 门控 / 计数 / 同步）
                    a.按信号来源：
                        信号来自其他定时器 / 内部模块（定时器级联同步） ： 选择：ITR0 ~ ITR3
                        信号来自专用 ETR 引脚（高速 / 抗干扰需求）      ： 选择：ETR1
                        信号来自普通通道引脚（CH1）                情况1： 只需要边沿触发（不管电平）    → 选 TI1-ED
                                                                  情况2： 需要电平 + 边沿控制（如门控） → 选 TI1FP1
                        信号来自普通通道引脚（CH2）                     ： 选择TI2FP2
                    b.按目标功能：
                        功能需求	                    推荐触发源	          核心原因
                        多定时器级联同步	            ITR0~ITR3	            内部信号，无引脚占用
                        高速外部脉冲计数（双边沿）	    ETR1	                专用高速通道，支持双边沿，不占用 TRGI
                        按键 / 传感器边沿触发启动	    TI1-ED	              仅响应边沿，不关心电平，适合纯事件触发
                        高电平期间计数（门控模式）	    TI1FP1/TI2FP2	        保留电平信息，可直接作为门控信号
                        外部事件同步复位计数器	        TI1FP1/TI2FP2/ETR1	  支持边沿触发复位，ETR1 适合高速场景
                        外部时钟模式 1（单边沿计数）	  TI1-ED/ETR1	          提供单边沿时钟信号，满足计数需求
            3.时钟源
                 01 Disable（禁用）            ： 不提供任何计数时钟，计数器完全停止工作。                        场景：暂时关闭定时器、省电或等待后续配置时使用。
                 02 Internal Clock（内部时钟） ： 使用 芯片内部时钟（APBx 总线时钟经倍频）作为计数源。            场景：普通延时、PWM 输出、自由运行计时、中断定时等绝大多数常规用途。
                 03 ETR2（外部触发输入2）      ： 使用 专用 ETR 引脚的外部信号 作为计数时钟（即 外部时钟模式2）。  场景：高速外部脉冲计数（如编码器、流量计）、需要双边沿计数、强抗干扰的工业环境。
            4. Channel1（通道1）
                 01 Disable（禁用）                                    ：通道完全关闭，不参与输入 / 输出，引脚恢复普通 GPIO 功能
                 02 Input Capture direct mode（直接输入捕获）          ：直接从对应通道引脚（如 CH1→TI1）输入，测量外部信号的频率、周期、脉宽，或记录事件发生的时间点。
                 03 Input Capture indirect mode（间接输入捕获）        ：交叉输入（如 CH2 可接 TI1，CH1 可接 TI2），编码器接口、特殊信号复用场景，或需要两路信号交叉测量时使用
                 04 Input Capture triggered by TRC（TRC 触发输入捕获） ：由 TRGI（触发源）同步触发捕获动作，需要外部事件同步捕获时（比如收到触发信号后才锁存计数器值）
                 05 Output Compare No Output（输出比较无输出）         ：计数器与捕获 / 比较寄存器匹配时，内部触发中断 / DMA，但不改变引脚电平，用于纯定时中断、事件触发，不需要对外输出信号
                 06 Output Compare CH1（通道 1 输出比较）              ：计数器匹配时，按配置翻转 / 置 0 / 置 1通道引脚电平
                 07 PWM Generation No Output（PWM 生成无输出）         ：内部生成 PWM 波形，不输出到引脚，仅触发中断 / DMA，用于软件 PWM、内部定时事件
                 08 PWM Generation CH1（通道 1 PWM 生成）              ：输出占空比可调的 PWM 波形到对应引脚，用于电机调速、LED 调光、DAC 模拟量输出等功率 / 模拟控制场景
                 09 Forced Output CH1（通道 1 强制输出模式）           ：强制把通道引脚电平拉为高或低，不受计数器匹配影响。
            5. Channel2（通道2） ：同上
            6. Channel3（通道3） ：同上
            7. Channel4（通道4） ：同上
            8. Combined Channels（组合通道）
                 01 Disable（禁用）            ： 通道各自独立工作，不做任何组合
                 02 Encoder Mode（编码器模式） ： 将 CH1 和 CH2 组合，直接对接增量式编码器的 A/B 相脉冲
                 03 PWM Input on CH1（PWM 输入模式）：将 CH1 和 CH2 组合，自动测量输入 PWM 信号的周期和占空比。CH1 捕获周期，CH2 捕获高电平时间。
                 04 PWM Input on CH2（PWM 输入模式）：将 CH1 和 CH2 组合，自动测量输入 PWM 信号的周期和占空比。CH2 捕获周期，CH1 捕获高电平时间。
                 05 XOR ON / Hall Sensor Mode（异或模式 / 霍尔传感器模式） ：将 CH1、CH2、CH3 三个通道输入做异或（XOR）运算，常用于连接三相霍尔传感器。
            9. Use ETR as Clearing Source（用 ETR 信号作为计数器清零源）   ：用 ETR 信号作为计数器清零源，在高速测量中同步复位计数器
           10. XOR activation（启用通道输入异或功能，常用于编码器接口）    ：单独开启通道输入异或功能，和 XOR ON / Hall Sensor Mode 配合使用
           11. One Pulse Mode（单脉冲模式）                               ：计数器溢出后自动停止，只产生一个脉冲，用于生成单次触发的精确脉冲信号。


                            0000 生成PWM波 0000
          TIM3 输出 PWM 的核心是：用内部时钟独立计数，让通道工作在 PWM 生成模式，关闭所有外部触发和单脉冲功能，靠 ARR 和 CCR 控制周期与占空比。
            1.TIM3模式
                 1. Slave Mode(从模式)                                        ： Disable ；               PWM 输出是定时器独立工作，不需要外部触发控制
                 2. Trigger Source（触发源）                                  ： Disable ；               无外部触发需求，不需要选择触发源
                 3. Clock Source（时钟源）                                    ： Internal Clock ；        PWM 频率由内部时钟分频决定，是最稳定、最通用的时钟源
                 4. Channel1（通道1）
                 5. Channel2（通道2）                                         ： PWM Generation CH2 ；    让 CH2 通道硬件输出 PWM 波形到对应引脚
                 6. Channel3（通道3）
                 7. Channel4（通道4）
                 8. Combined Channels（组合通道）                             ： Disable ；               单通道 PWM 不需要多通道组合
                 9. Use ETR as Clearing Source（用 ETR 信号作为计数器清零源）
                 10.XOR activation（启用通道输入异或功能，常用于编码器接口）     
                 11.One Pulse Mode（单脉冲模式）                              ： 不勾选 ；                PWM 需要连续输出，单脉冲模式会在一次溢出后停止
            注： 在F103zet6中，通道2的物理引脚为 PA7 / PB5 ，PA7是 TIM3_CH2 的默认复用引脚，可以通过 重映射（Remap） 把 TIM3_CH2 切换到 PB5 引脚；
                 因为PB5我们连接着LED灯，方便我们观察PWM波，所以重映射到PB5引脚（芯片图上单击PB5引脚切换就好）
            注： 因为之前LED工程我们进行了宏定义，重映射到PB5会改变PB5的名字，我们需要GPIO-->TIM把名字改回LED0
            2.TIM3配置
                 目标2KHz，凑数
                 1.预分频器：71
                 2.计数模式：向上
                 3.ARR：499
                 4.PWM模式 ：模式2（计数器从 0 到 ARR 递增时，小于 CCR 为低电平，大于为高电平）
                 5.Pulse :250 (就是 CCR 寄存器的值，决定 PWM 的高电平 / 低电平持续时间)  
                 6.CH Polarity : High (PWM 输出的有效电平极性： High：高电平为有效电平（占空比指高电平比例）;
                                                                Low：低电平为有效电平（占空比指低电平比例）)
            
             注：PWM波的占空比设置，核心就是CCR值得设置，也就是Pulse值得设置，上述：ARR=499,Pulse=250；也就是初始占空比50左右，向上计数。             
                 当CNT<CCRx,IO输出无效电平；当CNT>=CCRx时，IO输出有效电平 。

            3.代码          
                  // 1. 头文件包含
                  #include "main.h"
                  // 2. 全局变量 / 宏定义
                  // 3. 函数声明
                  void SystemClock_Config(void);

                  // 4. 主函数！程序入口
                  int main(void)
                  {
                                                                ////////////////////////////////////////////////////////////
                                                                uint8_t  dir = 1;
                                                                uint16_t val =250;
                                                                ////////////////////////////////////////////////////////////
                      // 初始化
                      HAL_Init();
                      SystemClock_Config();
                      MX_GPIO_Init();
                      MX_USART1_UART_Init();
                                                                ////////////////////////////////////////////////////////////
                                                                HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
                                                                ////////////////////////////////////////////////////////////
                      while (1)
                      // 死循环！程序一直在这里跑
                      {
                                                                ////////////////////////////////////////////////////////////
                                                                 if(dir==1)
	                                                                 {
	                                                               	  val++;
	                                                                 }
	                                                                 else
	                                                                 {
	                                                               	  val--;
	                                                                 }
                                                                   
                                                               	  if(val>=300)
	                                                                 {
	                                                               	  dir = 0;
	                                                                 }
	                                                                 if(val==0)
	                                                                 {
	                                                               	  dir =1;
                                                               	  }
                                                               	  HAL_Delay(10);
                                                                  
                                                               	  __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2,val);
                                                                ////////////////////////////////////////////////////////////
                      }
                  }
                  // 5. 系统配置函数（时钟、初始化）
                  void SystemClock_Config(void){}
                  // 6. 错误处理函数
                  void Error_Handler(void){}

                  核心代码注：
                             HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
                             作用：开启 TIM3 通道 2 的 PWM 波形输出（让引脚真正出波）。
                             入口参数去TIM.c复制

                             __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_2,val);
                             作用：动态修改 PWM 占空比，就是改 CCR 值，val 越大，占空比越高


                             代码逻辑：
                                     1. HAL_TIM_PWM_Start();       启动PWM输出
                                     2. __HAL_TIM_SET_COMPARE();   动态修改CCRx值，调节占空比
                                     3. 实现CCRx得动态修改：
                                                            __HAL_TIM_SET_COMPARE(); 函数的第三个入口参数值是Pulse的值，也就是CCRx的值
                                                            为让其一直变化，创建变量 val 作为函数入口参数
                                                             uint8_t  dir = 1;
                                                             uint16_t val =250;       //代表的CCRx为16位寄存器值

                                                            控制变量变化代码：    
                                                            if(dir==1)                 //初始变量为真
	                                                                 {
	                                                               	  val++;             //初始为真时执行，val递增
	                                                                 }
	                                                                 else
	                                                                 {
	                                                               	  val--;              //为假时递减
	                                                                 }
                                                                   
                                                               	  if(val>=300)          //当递增到300时（300-500亮度变化不明显，所以设置300）
	                                                                 {
	                                                               	  dir = 0;            //改变初始条件，让其执行为假时语句 ：递减
	                                                                 }
	                                                                 if(val==0)           //递减到0时，再次改变初始条件，让其为真
	                                                                 {
	                                                               	  dir =1;
                                                               	  }
                                                               	  HAL_Delay(10);       //轮询变化太快了，为了明显观察呼吸灯效果，设置延时降速
                                                                  

                                                            
              
              
              
            
               
    
                  
                
             
