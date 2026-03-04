// 1. 头文件包含
#include "main.h"
// 2. 全局变量 / 宏定义
// 3. 函数声明
void SystemClock_Config(void);

// 4. 主函数！程序入口
int main(void)
{
    // 初始化
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_USART1_UART_Init();
    
    while (1)
    // 死循环！程序一直在这里跑
    {
        // 你写的主逻辑
    }
}
// 5. 系统配置函数（时钟、初始化）
void SystemClock_Config(void){}
// 6. 错误处理函数
void Error_Handler(void){}
