
#include "main.h"
  //main.h : 主要包含 1-核心头文件，2-晶振频率，引脚/波特率等硬件参数宏，3-全局声明 外设句柄extern声明，全局变量，函数原型//
  //注BEGIN：
       extern 关键字（储存类型说明符）
              用于外部声明，声明某一全局变量 / 函数的标识符已在其它编译单元中完成定义，实现跨编译单元访问。
              例子：
                   gpio.c : GPIO句柄在这里定义-造东西、占内存
                   main.h : 写 extern 声明，只声明，非定义，不占内存》（给使用权）
                   main.c : 直接使用GPIO句柄。
  //注END
#include "gpio.h"
  
void SystemClock_Config(void);
  //调用函数之前，对系统时钟配置函数进行声明

int main(void)
  //程序执行的起点
{

  HAL_Init();
  	//初始化HAL（硬件抽象层）库，具体执行以下操作
      1-HAL库数据结构初始化  - 设置HAL库状态为HAL_OK
      2-配置中断优先级分组   - 设置NVIC中断优先级分组为4位抢占优先级，0位子优先级
      3-配置SysTick定时器   - 配置SysTick每1ms中断一次
      4-初始化底层硬件抽象层 - 调用HAL_MspInit() - 这是弱函数，用户可以重写，通常用于初始化：时钟、GPIO、DMA等底层硬件
      5-初始化全局变量      - 
  
  SystemClock_Config();
    //调用系统时钟配置函数，用户自定义函数，用于配置STM32的复杂时钟树
 
  MX_GPIO_Init();
    //GPIO初始化，定义引脚，使能时钟等
  
  while (1)
     //主循环
  {
   
    HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, GPIO_PIN_SET);
	  HAL_GPIO_WritePin(LED1_GPIO_Port, LED1_Pin, GPIO_PIN_SET);
	  HAL_Delay(500);
	  HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, GPIO_PIN_RESET);
	  HAL_GPIO_WritePin(LED1_GPIO_Port, LED1_Pin, GPIO_PIN_RESET);
	  HAL_Delay(500);
   
  }
}

void SystemClock_Config(void)
  //注释START
    13行为系统时钟配置函数声明
    28行为系统时钟配置函数调用
    48行为系统时钟配置函数定义
  //注释END
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    //振荡器配置表
    //RCC = Reset and Clock Control（复位和时钟控制）
    //Oscillator = 振荡器
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
    //时钟树配置表
    //Clk : clock缩写
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    //PLL = Phase Locked Loop（锁相环） = ​频率倍增器
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
    //应用振荡器配置
    //如果执行失败（!=），执行错误处理（ Error_Handler()）
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

void Error_Handler(void)
  //错误处理函数，接上述应用振荡器配置
{
  __disable_irq();
    //关闭所有中断
  while (1)
  {
    //卡死在这里，等待修正错误
  }
  
#ifdef USE_FULL_ASSERT
  //调试工具

void assert_failed(uint8_t *file, uint32_t line)
{
 
}
#endif 
