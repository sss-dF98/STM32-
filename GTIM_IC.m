1.通用定时器模式与配置
  通用定时器（TIM2/TIM3/TIM4 等）的输入功能，核心就两类：
  01.输入捕获（Input Capture）  作用：测量外部信号的边沿时刻，计算脉冲高低电平时间、信号周期频率等
                               硬件路径：外部引脚 → 输入滤波 → 边沿检测 → 捕获寄存器 → 触发中断 / DMA
                               关键寄存器：
                                        CCR1~4：捕获时锁存计数器的值
                                        TIMx_CCER：选择上升 / 下降 / 双边沿捕获
                                        TIMx_CCMR1：配置为输入模式、分频、滤波
  02.PWM 输入（PWM Input）      作用：专门测量外部 PWM 信号周期、占空比
                               原理——用两个通道绑定：
                                                   CH1 测周期（上升沿→捕获 CCR1）
                                                   CH2 测高电平时间（下降沿→捕获 CCR2）
                               硬件路径：外部引脚 → 输入滤波 → 边沿检测 → 捕获寄存器 → 触发中断 / DMA
2.输入捕获案例：
  01.配置MX
          ：通道1，输入捕获模式，通道1对应引脚为PA0，注意后续GPIO名字改回来，不要和按键工程的宏定义冲突
          ：确定计时器工作票嫩绿：Tout=[(ARR+1)*(PSC+1)]/Ft
          ：选择计时器工作频率为1MHz，则 PSC选择71
          ：计数时间尽可能的长，自动重装载ARR选择最大
          ：NVIC等配置
  02.代码     
          代码逻辑：上升沿，下降沿捕获标志位都为0  ：说明还未开始测量脉宽，触发输入捕获回调函数的是上升沿捕获
                    上升沿捕获标志位为1，下降沿为0 ：说明上升沿捕获完了，本次触发输入捕获中断的是下降沿
                    上升沿，下降沿捕获标志位都为1  ： 说明一个周期捕获结束了，可以开始计算脉宽了
                    
          // 1. 头文件包含
          #include "main.h"
          // 2. 全局变量 / 宏定义
                                                    /////////////////////////////////////////////////////////////////////////////                                     
                                                    uint8_t rising_flag = 0;             1 ：上升沿捕获完成
                                                    uint8_t falling_flag = 0;            1 ：下降沿捕获完成
                                                    uint8_t overflow_val = 0;            1 ：定时器溢出次数
                                                    uint16_t cnt_val = 0;                  ：
                                                    uint32_t temp = 0;                     ：
                                                    //////////////////////////////////////////////////////////////////////////////
          // 3. 函数声明
          void SystemClock_Config(void);
                                                    //////////////////////////////////////////////////////////////////////////////
                                                    int __io_putchar(int ch)
                                                    {
                                                    	HAL_UART_Transmit(&huart1, (uint8_t*)&ch, 1, 1000);
                                                    	return ch;
                                                    }
                                                                        注：内部系统规定的printf底层函数，将printf的内容通过串口输出出去
                                                                        / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
                                                    void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)         注：TIM 输入捕获中断回调函数
                                                     {
                                                    	  if(htim->Instance == TIM5)                                   注 01
                                                    	  {
                                                            if(falling_flag == 0)                                    注：下降沿还未捕获
                                                            {
                                                            	if(rising_flag == 1)                                   注：上升沿已经捕获（说明此次触发捕获中断的下降沿）
        	                                                    {
        	                                                    	falling_flag = 1;                                    注：下升沿捕获标志位置1
                                                            		cnt_val = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1);                           注：读取计数器的值，并赋值给cnt_val
                                                            		__HAL_TIM_SET_CAPTUREPOLARITY(htim,TIM_CHANNEL_1,TIM_INPUTCHANNELPOLARITY_RISING);  注：切换边沿捕获模式为上升沿捕获，为下次准备
                                                            	}
                                                            	else                         注：上升沿还未捕获（本次捕获上升沿 注：fall_ing = 0 为设计非错误）
                                                            	{
                                                            		rising_flag = 0;
        	                                                    	falling_flag = 0;
        	                                                    	overflow_val = 0;
        	                                                    	cnt_val = 0;                        注：其实代码看起来有些冗余，其实目的就是保证上升沿捕获开始前，把参数值都恢复到初始状态

        	                                                    	rising_flag = 1;                    注：上升沿捕获成功标志位置1
        	                                                    	__HAL_TIM_DISABLE(htim);            注：关闭定时器
        	                                                    	__HAL_TIM_SET_COUNTER(htim,0);      注：将计数器计数值清零，使其从0开始计数
        		                                                    __HAL_TIM_SET_CAPTUREPOLARITY(htim,TIM_CHANNEL_1,TIM_INPUTCHANNELPOLARITY_FALLING);   注：切换边沿捕获模式为下降沿捕获
        	                                                    	__HAL_TIM_ENABLE(htim);             注:开启时钟
                                                            	}
                                                            }
	                                                      }
                                                     }

                                                    void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)              注：TIM 更新中断回调函数
                                                    {
                                                          if(htim->Instance == TIM5)                 注：判断触发更新中断的定时器是否是TIM5
                                                          {
                                                        	  if(falling_flag == 0)                    注：下降沿还未捕获
    	                                                      {
    	                                                    	  if(rising_flag == 0)                   注：上升沿还未捕获
    		                                                      {
    		                                                    	  if((overflow_val & 0xFF) == 0xFF)    注：判断溢出时间次数是否超过设置的变量范围
    		                                                    	  {
    		                                                    		  falling_flag = 1;                  注：下降沿捕获成功标志位置1（强制捕获成功）
    		                                                    		  __HAL_TIM_SET_CAPTUREPOLARITY(htim,TIM_CHANNEL_1,TIM_INPUTCHANNELPOLARITY_RISING);   注：设置边沿捕获方式为上升沿捕获
    		                                                    		  cnt_val = 0XFF;                    注：让计数器的值等于最大值
    		                                                    	  }
    		                                                    	  else
    		                                                    	  {
    		                                                    	      overflow_val++;                  注：溢出时间次数未超过变量允许范围：触发一次更新中断就将更新次数 overflow_val 值加1
    		                                                    	  }
    	                                                    	  }
                                                        	  }
                                                          }
                                                      }
                                                                        /////////////////////////////////////////////////////////////////////////////////
          // 4. 主函数！程序入口
          int main(void)
          {
              // 初始化
              HAL_Init();
              SystemClock_Config();
              MX_GPIO_Init();
              MX_USART1_UART_Init();
                                                                         ///////////////////////////////////////////////////////////////////////////////////
                                                                          HAL_TIM_Base_Start_IT(&htim5);                  注：开启定时器计数加中断功能 ：PWM输出通道使能时没有这个是因为PWM输出使能函数内部包含这个
                                                                          HAL_TIM_IC_Start_IT(&htim5, TIM_CHANNEL_1);     注：开启定时器输入捕获通道
                                                                         //////////////////////////////////////////////////////////////////////////////////
              while (1)
              // 死循环！程序一直在这里跑
              {
                                                                        ///////////////////////////////////////////////////////////////////////////////////
                                                                        if(falling_flag == 1)      注：下降沿捕获成功
                                                                        {
                                                                        	temp = overflow_val*65536;    注：高电平时间 = [ 溢出次数 *（ARR + 1）+ CCR2 ] / TIM-CLK
                                                                        	temp += cnt_val;
                                                                        	printf("高电平脉宽长度：%ld us\r\n",temp);    注：输出脉宽长度
                                                                        	falling_flag = 0;
                                                                        	rising_flag = 0;                              注：初始化参数
                                                                        }
                                                                        //////////////////////////////////////////////////////////////////////////////////
              }
          }
          // 5. 系统配置函数（时钟、初始化）
          void SystemClock_Config(void){}
          // 6. 错误处理函数
          void Error_Handler(void){}

      03 代码注解
              01.代码 ： htim->Instance == TIM5
                       001.htim是什么？
                           htim 是 TIM_HandleTypeDef 类型的结构体指针 / 变量，它是 ST 官方 HAL 库设计的软件句柄
                       002.为什么要有htim？
                           硬件定时器有很多个（TIM1~TIM17），功能几乎一样
                           代码不能为每个定时器写一套逻辑，必须通用化
                           所以用 htim 统一代表「任意一个定时器」
                       003.如何定义一个结构体？
                           a.方法1
                           typedef struct
                           {
                               成员1;
                               成员2;
                           } 结构体名字;
                           b.方法2
                           struct 名字
                           {
                               成员1;
                               成员2;
                           };
                           注：struct = 定义结构体
                               typedef = 给类型起别名，规则：typedef 原来的类型 新名字;
                               也就是说方法1就是应用 typedef 关键词的方法2
                       003.TIM_HandleTypeDef是什么？
                          a.语法级定义：
                           typedef struct
                           {
                               TIM_TypeDef           *Instance;
                               TIM_Base_InitTypeDef   Init;
                               HAL_LockTypeDef        Lock;
                               HAL_TIM_StateTypeDef   State;
                               ...
                           } TIM_HandleTypeDef;
                           b.语义定义：
                             TIM_HandleTypeDef 是 STM32 HAL 库定义的一个结构体类型（struct type）。
                             它用于封装定时器外设的全部软件层信息，供库函数操作定时器使用。
                       005.TIM_HandleTypeDef存在的意义是什么？
                           把「硬件地址 + 配置 + 状态」打包在一起，如果没有它就会复杂化：HAL_TIM_Init(地址, 配置, 状态);
                           让一套代码支持所有定时器，实现通用化
                       004.->是什么？
                           指针访问结构体成员
                           .  是给普通变量用的
                           -> 是给指针变量用的
                           函数入口参数：TIM_HandleTypeDef *htim
                           意思是：定义一个【指针变量】，这个指针指向【TIM_HandleTypeDef 结构体】
                           所以htim是一个指针，要用->
                           类似于：int *a;
                           意思是：定义一个指向 int 的指针a
                       006.instance 是什么？除了instance 还需要掌握哪些？
                           instance是结构体 TIM_HandleTypeDef 里面的成员，还需掌握：
                           001.htim->Instance ：判断是哪个定时器硬件
                           002.htim->Init     ：读取 / 修改定时器配置
                               如：htim->Init.Prescaler  预分频系数
                                   htim->Init.Period     重装载值
                           003.htim->State    :判断定时器是否忙
                               如：htim->State == HAL_TIM_STATE_READY
                                   htim->State == HAL_TIM_STATE_BUSY
                       007.凭什么是TIM5？不是别的名字？别的外设？
                           TIM5     ： 硬件层面的「固定地址宏」
                           语法定义 ：#define TIM5   ((TIM_TypeDef *)0x40000C00)
                           所有 STM32 中断 / 回调函数里，要判断 “是哪个外设触发的”
                           永远都是这个格式  ：外设句柄->Instance == 外设编号
                           比如： 
                                 定时器：htim->Instance == TIM5
                                 串口：huart->Instance == USART1
                                 I2C：hi2c->Instance == I2C1
                                 SPI：hspi->Instance == SPI2
                                 ADC：hadc->Instance == ADC1
                            格式 100% 一样，只是换名字！
            02.库函数
                     001. HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim)  ：输入捕获中断回调函数，脉冲到来 / 结束时，硬件自动进这个函数
                     002. HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1)       ：读取捕获到的计数器值
                     003. __HAL_TIM_SET_CAPTUREPOLARITY(...)                   ：设置捕获极性
                     004. __HAL_TIM_SET_COUNTER(htim, 0)                       ：给定时器计数器清零
                     005. HAL_TIM_PeriodElapsedCallback(htim)                  ：定时器溢出中断回调
                     006. HAL_TIM_IC_Start_IT(&htim5, TIM_CHANNEL_1)           ：开启输入捕获中断
                     007. HAL_TIM_Base_Start_IT(&htim5)                        ：开启定时器溢出中断

                     注：为什么有的入口参数是htim,有的是 &htim5 ？实际应用中我们该如何区分？
                     规则： 自己主动调用函数 → 必须写 &htim5
                            在回调函数里面用 → 直接用 htim
                          因为函数需要指针：自己传参就用 &htim5 取地址，回调里已经是 htim 指针就直接用
            03.相关寄存器
                    001.CNT 计数器寄存器（核心）
                        全称：Counter
                        作用：从 0 开始自动往上数数
                        每来一个时钟，+1
                        溢出值：65535                注：时基模块学过
                    002.CCR1 捕获寄存器（存边沿时刻）
                        全称：Capture/Compare Register 1
                        作用：脉冲边沿到来时，自动把 CNT 的值存进 CCR1   注：脉冲宽度计算公式里面的CCR2，就是下降沿到来时的边沿时刻（CCR1代表上升沿，所以CCR2代表下降沿）
                    003.CCER 极性选择寄存器（选上升沿 / 下降沿）
                        作用：设置触发捕获的边沿
                        0 = 上升沿捕获
                        1 = 下降沿捕获
                    004.SR 中断标志寄存器（判断事件）
                        作用：标记发生了什么事件
                        位 0 = 计数器溢出
                        位 1 = 捕获中断
                     
              
                         
                         
                                 
                           
                           
                           
                       























      

         
  
 
