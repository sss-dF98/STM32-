
//beep.h和led.h中进行宏定义
#define BEEP(x)      x?     HAL_GPIO_WritePin(BEEP_GPIO_Port, BEEP_Pin, GPIO_PIN_SET):\
		                    HAL_GPIO_WritePin(BEEP_GPIO_Port, BEEP_Pin, GPIO_PIN_RESET);
#define LED0(x)      x?   HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, GPIO_PIN_SET):\
		                  HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, GPIO_PIN_RESET);
#define LED1(x)      x?   HAL_GPIO_WritePin(LED1_GPIO_Port, LED1_Pin, GPIO_PIN_SET):\
		                  HAL_GPIO_WritePin(LED1_GPIO_Port, LED1_Pin, GPIO_PIN_RESET);
                      
           //注释START---c语言 运算符总结
               1.算数运算符
                 加（+）  减（-）  乘（*）  除（/）  取模、求余（%）
                 
               2.关系运算符 真（1）、假（0）
                 ==	  等于	    a == b
                 !=	  不等于    	a != b
                 >	  大于	    a > b
                 <	  小于	    a < b
                 >=	  大于等于 	a >= b
                 <=	  小于等于 	a <= b
                 
               3.逻辑运算符
                 &&	  逻辑与   	a && b	如果a为假，b不被求值     同真才真
                 ||	  逻辑或     a || b  如果a为真，b不被执行    一真则真
                 !	  逻辑非	      !a	  单目运算符              真变假，假变真
                   //例子： 只有两个按键同时按下才点亮LED
                             void logical_and_hal_example1(void) {
                               // 定义引脚
                                   #define BUTTON1_PIN GPIO_PIN_0
                                   #define BUTTON2_PIN GPIO_PIN_1
                                   #define LED_PIN GPIO_PIN_5
                               // 读取按键状态
                                   GPIO_PinState btn1_state = HAL_GPIO_ReadPin(GPIOA, BUTTON1_PIN);
                                   GPIO_PinState btn2_state = HAL_GPIO_ReadPin(GPIOA, BUTTON2_PIN);
                               // 逻辑与：两个按键都按下
                                   if (btn1_state == GPIO_PIN_SET && btn2_state == GPIO_PIN_SET) {
                              // 安全启动条件满足
                                  HAL_GPIO_WritePin(GPIOA, LED_PIN, GPIO_PIN_SET);  // LED亮
                                  } else {
                                  HAL_GPIO_WritePin(GPIOA, LED_PIN, GPIO_PIN_RESET); // LED灭
                                  }
                                }
                   //例子END
                   
               4.位运算符（嵌入式核心）
                  位与    	&    两位都为1时结果为1	    清除特定位、检查特定位
                  位或	    |	   两位有1时结果为1	      设置特定位、合并位域
                  位异或   	^	   两位不同时结果为1	      切换特定位、简单加密
                  位取反   	~	   所有位0变1，1变0	      生成掩码、位反转
                  左移	    <<	 所有位左移，低位补0	    乘以2^n、创建位掩码
                  右移    	>>	 所有位右移，高位补0	    除以2^n、提取高位
                  //
                    1. 位与 & (AND)----------------两位都为1时，结果才为1。常用于“屏蔽”或“检查”特定位。
​                        //示例​：
                            uint8_t a = 0b11001100; // 数值a
                            uint8_t b = 0b11110000; // 掩码b
                            uint8_t c = a & b;      // 位与运算
                              // a&b: 1 1 0 0 0 0 0 0  // （用来屏蔽a的低4位）
                             // 解释：掩码b的高4位为1，所以保留了a的高4位；低4位为0，清除了a的低4位。
                             
                    2. 位或 | (OR)-----------------两位中有一个为1时，结果就为1。常用于“设置”或“打开”特定位。
​                        //示例​：
                            uint8_t a = 0b11000011;
                            uint8_t b = 0b00011000; // 希望设置a的第3、4位
                            uint8_t c = a | b;      // 位或运算
                             // a|b: 1 1 0 1 1 0 1 1  // 设置a的第3、4位
                             // 解释：b中为1的第3、4位，在结果中被置1；a中原有的1位保持不变。
                             
                   3. 位异或 ^ (XOR)---------------两位不相同时结果为1，相同时为0。常用于“翻转”或“切换”特定位。
                        //​特性​：一个数两次异或同一个数，等于其本身 (a ^ b) ^ b = a。
                        //​示例​：
                            uint8_t a = 0b11001100;
                            uint8_t b = 0b00001111; // 希望翻转a的低4位（与0异或不变。与1异或反转）
                            uint8_t c = a ^ b;      // 位异或运算
                             // a^b: 1 1 0 0 0 0 1 1  // 翻转a的低4位
                             // 解释：b中为1的低4位，使得a对应的低4位被翻转（0变1，1变0）。
                             
                   4. 位取反 ~ (NOT)----------------​一元运算符。将操作数的每一位取反（1变0，0变1）。常用于创建掩码。
​                         //示例​：
                             uint8_t a = 0b00001111;
                             uint8_t b = ~a;         // 位取反运算
                              //  ~a: 1 1 1 1 0 0 0 0  // 结果b = 0b11110000
                              // 解释：a的所有位被反转。常用来生成与原来相反的掩码。
                              
                   5. 左移 << (Left Shift)------------将操作数的所有位向左移动指定位数，高位丢弃，低位补0。相当于乘以2^n。
                        //​示例​：
                            uint8_t a = 0b00010001; // 十进制 17
                            uint8_t b = a << 2;     // 左移2位
                              // a<<2: 0 1 0 0 0 1 0 0  // 结果b = 0b01000100 (十进制 68)
                              // 解释：整体左移2位，右边空出补0。17 * (2^2) = 68。
                              
                   6. 右移 >> (Right Shift)------------将操作数的所有位向右移动指定位数，低位丢弃。对于无符号数，高位补0。相当于除以2^n​（向下取整）。
                        //​示例​：
                            uint8_t a = 0b10010000; // 十进制 144
                            uint8_t b = a >> 3;     // 右移3位
                              // a>>3: 0 0 0 1 0 0 1 0  // 结果b = 0b00010010 (十进制 18)
                              // 解释：整体右移3位，左边空出补0。144 / (2^3) = 18。

               5.赋值运算符
                 =	   赋值	            a = b	无
                 +=	   加后赋值      	a += b	a = a + b
                 -=	   减后赋值      	a -= b	a = a - b
                 *=	   乘后赋值      	a *= b	a = a * b
                 /=	   除后赋值	        a /= b	a = a / b
                 %=	   取模后赋值	    a %= b	a = a % b
                 &=	   位与后赋值	    a &= b	a = a & b
                 |=    位或后赋值	    a |= b  a = a | b
                 ^=	位异或后赋值	        a ^= b	a = a ^ b
                 <<=	左移后赋值	    a <<= b	a = a << b
                 >>=	右移后赋值	    a >>= b	a = a >> b

                6.条件运算符
                  形式：条件 ? 表达式1 : 表达式2
                    //例：
                      #define LED0(x)      x?   HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, GPIO_PIN_SET):\
		                  HAL_GPIO_WritePin(LED0_GPIO_Port, LED0_Pin, GPIO_PIN_RESET);
                  如果条件为真，返回表达式1的值
                  如果条件为假，返回表达式2的值

                7.逗号运算符
                  形式：表达式1, 表达式2, ..., 表达式n
                  从左到右依次求值
                  整个表达式的结果是o最后一个表达式o的值

                8.指针运算符
                  &   ： 取地址运算符
                  *   ： 解引用运算符
                    //例子----读取指针所指向的内存地址中存储的内容
                        int value = 42;         // 定义一个整型变量
                        int *ptr = &value;      // ptr是指向value的指针
                     // 解引用操作
                          int data = *ptr;        // 读取ptr指向的值（42）
                          *ptr = 100;             // 修改ptr指向的值（将value改为100）  
                   ->  ： 箭头运算符------通过指针访问结构体成员（结构体指针成员访问运算符）
                      //注释：
                         是通过结构体指针直接访问其成员变量的快捷方式，本质上是先解引用指针再访问成员的语法糖
                        // 两种写法完全等价：
                            ptr->member     // 使用箭头运算符
                            （*ptr）.member   // 先解引用，再用点运算符
                       // 示例：
                            Point *ptr = &p;
                            ptr->x = 5;          // 简洁写法
                            （*ptr）.x = 5;        // 繁琐写法，但功能相同

                9. 求字节数运算符
                  sizeof  ： 返回类型或变量的大小（字节数）

                10.强制类型转换运算符
                  (类型)：将值转换为指定类型

                11. 分量运算符
                   .  ：  结构体/共用体成员访问
                  ->  ：  通过指针访问结构体/共用体成员

                12. 下标运算符
                  [] ： 数组元素访问

                13. 特殊运算符
                  ++	          自增	             i++ 或 ++i
                  --              自减	             i-- 或 --i
                  ()	          函数调用            function()
                  (type){init}	  复合字面量	        (int){5}

                  while (1)
            //蜂鸣器实验
               {
	               LED0(1);
	               BEEP(1);
	               HAL_Delay(500);
	               LED0(0);
	               BEEP(0);
	               HAL_Delay(500);
                /* USER CODE END WHILE */
                /* USER CODE BEGIN 3 */
              }


                      
                            
