                                               000 时钟树 000
                  
高速主线：
          01.三个基础时钟源
               HSI 高速内部时钟 ： 内置 RC 振荡器，精度稳定性差，启动默认时钟、应急时钟。频率：8MHz / 16MHz（依型号）
               HSE 高速外部时钟 ： 接外部晶振，系统主时钟最稳定来源。频率：8MHz / 25MHz最常用，范围4~48MHz
               //LSE 低速外部时钟 ： 32.768kHz 晶振，RTC 实时时钟、低功耗计时
          02.PLL锁相环
               把低频时钟倍频到高频，是系统速度的核心
               输入 ：HSE / HSI -------> 输出 ：系统时钟 SYSCLK
          03.三大总线时钟
           ！！！系统时钟SYSCLK 经过AHB预分频 → 得到AHB时钟HCLK ， HCLK再经过 APB1/APB2 预分频 → 得到外设总线时钟 PCLK1 / PCLK2
               AHB  总线时钟（HCLK）：      给：内核、存储器、DMA、AHB 外设
               APB2 高速外设总线（PCLK2）： 给：GPIO、ADC、USART1、TIM1/TIM8 高级定时器等高速外设
               APB1 低速外设总线（PCLK1）： 给：I2C、SPI2/3、USART2/3/4/5、普通定时器 TIM2~7等低速外设
               注：
                   特殊的，定时器为了保证定时精准，尽可能的应该挂在APB2高速外设时钟总线上，但是出于成本的考量，全挂在APB2上不现实，
                  实际：高级定时器（如 TIM1、TIM8）→ 挂在 APB2 总线； 通用 / 基本定时器（如 TIM2~7）→ 挂在 APB1 总线
                  APB1外设时钟PCLK1 / APB2外设时钟PCLK2 输送给定时器的倍频模块，倍频模块功能：
                                                                                             当 APB 预分频器 = 1 时：TIMxCLK = PCLK
                                                                                             当 APB 预分频器 > 1 时：TIMxCLK = 2 × PCLK
                  所以往往见到的无论APB1还是APB2上的定时器，其定时器时钟都是72MHz.                  
          04.经典时钟走向
                                       HSE 外部晶振
                                            ↓
                                PLL 倍频（例如 8MHz → 72MHz）
                                            ↓
                                 SYSCLK 系统时钟（72MHz）
                                            ↓
                                    AHB(HCLK) = 72MHz
                                            ↓
                            ├─ APB2(PCLK2) = 72MHz （高速外设）
                            └─ APB1(PCLK1) = 36MHz （低速外设）
低速支线(完全隔离)：
          01. LSI → IWDG（独立看门狗）
          02. LSE → RTC（实时时钟）
                                            
                                             000 基本定时器 000
1.基本定时器的三大寄存器
  TIMx-PSC —— 预分频器寄存器   ：16 位寄存器，写入的值范围：0 ~ 65535，定时器计数频率 = TIMx-CLK / (PSC + 1)
  TIMx-ARR —— 自动重装载寄存器 ：16 位寄存器，写入的值范围：0 ~ 65535，定时时间 = (ARR + 1) * 计数周期。计数周期：计数一个需要的时间，由计数频率决定
  TIMx-CNT —— 计数器寄存器     ：16 位寄存器，写入的值范围：0 ~ 65535，真正在 “数数” 的硬件寄存器
2.基本定时器的时钟线
  TIMx-CLK ---> PSC预分频器 ---> 计数器时钟 CNT-CLK ---> 溢出
                                       ↓（比较）
                                ARR 自动重装载寄存器
3.溢出时间计算：
                 溢出时间 = [(PSC + 1) × (ARR + 1)] / 定时器时钟 TIMxCLK
          注：和看门狗溢出时间计算原理相同，时钟频率下单周期时间 × 周期数，周期数 = 分频系数 × 计数次数
              而PSC和ARR都是十六位寄存器，从 0 开始计数，0，1，2，3，4，实际起效果的数值比设置的输入数大1.
              所以 ： 分频系数 = PSC + 1 ; 计数次数 = ARR + 1 ；
4.溢出后会发生：
  CNT 置零； 触发溢出更新中断； 状态寄存器置位，TIM-SR.UIF = 1(更新中断标志位 = 1)；

                                          000 实验 000

// 1. 头文件包含
#include "main.h"
// 2. 全局变量 / 宏定义
// 3. 函数声明
void SystemClock_Config(void);
                               //////////////////////////////////////////////////////////////////////////////////////// 定义更新中断回调函数:
                                                     stm32f1xx-it.c
                                                           ↓
                                              HAL_TIM_IRQHandler(&htim6);
                                                           ↓
                                  if ((itflag & (TIM_FLAG_UPDATE)) == (TIM_FLAG_UPDATE));            (找到判断更新中断语句，语句含义：检测更新中断标志位是否置1)
                                                           ↓
                                            HAL_TIM_PeriodElapsedCallback(htim);                    （找到执行更新中断语句，ctrl进去）
                                                           ↓
                              _weak void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)      (更新中断回调函数弱定义)
                               ///////////////////////////////////////////////////////////////////////////////////////////////////// 在main.c中重定义回调函数，注意：！！要定义在主函数main外面  
                                 void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
                                  {
	                                  HAL_GPIO_TogglePin(LED1_GPIO_Port, LED1_Pin);
                                  }
                               /////////////////////////////////////////////////////////////////////
// 4. 主函数！程序入口
int main(void)
{
    // 初始化
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_USART1_UART_Init();
    MX_TIM6_Init();        ///////////////基本定时器初始化
                                    /////////////////////////////////////////////////////////////////////
                                    HAL_TIM_Base_Start_IT(&htim6);   
                                    注：
                                    1.这是定时开启语句，MX里面配置好，但是并不代表就一直开始数数了，这就是开始数数的开关
                                    2.尾缀 _IT 的意思是开启计数的同时并开启更新中断，不带就仅仅开启计数功能
                                    /////////////////////////////////////////////////////////////////////
    while (1)
    {
    }
}
// 5. 系统配置函数（时钟、初始化）
void SystemClock_Config(void){}
// 6. 错误处理函数
void Error_Handler(void){}

注：总的来说，BTIM 的使用需要不仅仅需要在MX配置好
    还需要你用 HAL_TIM_Base_Start_IT(&htimx);来激活它
    单纯想开始计数就 HAL_TIM_Base_Start(&htimx);
    想计数并且使用更新触发中断，那就用 HAL_TIM_Base_Start_IT(&htimx);
               
               
  
