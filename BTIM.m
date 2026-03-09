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
1
               
               
  
