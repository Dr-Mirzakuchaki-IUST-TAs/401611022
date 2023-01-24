library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


use std.textio.all;
use std.env.finish;

entity AD4030_FSM_tb is
end AD4030_FSM_tb;



architecture Behavioral of AD4030_FSM_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    COMPONENT AD4030_FSM
    PORT(
        DATA    : OUT    STD_LOGIC_VECTOR(23 DOWNTO 0); 
        CLOCK   : IN     STD_LOGIC;                           
        START   : IN     STD_LOGIC;                           
        DRDY    : OUT    STD_LOGIC;                           
        RESET   : IN     STD_LOGIC;
        ---------------------------                                                              
        MOSI    : OUT    STD_LOGIC;                           
        MISO    : IN     STD_LOGIC;                           
        SCLK    : BUFFER STD_LOGIC;                            
        CS      : OUT    STD_LOGIC;
        RST     : OUT    STD_LOGIC;
        CNV     : OUT    STD_LOGIC;
        BUSY    : IN     STD_LOGIC
        );
    END COMPONENT;

    signal tb_DATA      :    std_logic_vector(23 downto 0) := X"000000";
    signal tb_CLOCK     :    std_logic := '0';
    signal tb_START     :    std_logic := '0';
    signal tb_DRDY      :    std_logic := '0';
    signal tb_RESET     :    std_logic := '1';

    signal tb_MOSI      :    std_logic := '0';
    signal tb_MISO      :    std_logic := '0';
    signal tb_SCLK      :    std_logic := '0';
    signal tb_CS        :    std_logic := '0';
    signal tb_RST       :    std_logic := '0';
    signal tb_CNV       :    std_logic := '0';
    signal tb_BUSY      :    std_logic := '0';
    
    
    --===================================================================================
    PROCEDURE AD4030_BEHAVIOR (
            SIGNAL MISO : OUT STD_LOGIC;
            SIGNAL MOSI : IN  STD_LOGIC;
            SIGNAL SCLK : IN  STD_LOGIC;
            SIGNAL CS   : IN  STD_LOGIC;
            SIGNAL RST  : IN  STD_LOGIC;
            SIGNAL CNV  : IN  STD_LOGIC;
            SIGNAL BUSY : OUT STD_LOGIC  
        ) IS  
 
    VARIABLE SPI_RX : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');     
    VARIABLE SPI_TX : STD_LOGIC_VECTOR(23 DOWNTO 0) := X"000000";  
    -----------------------------------------------------------    
    PROCEDURE SPI_SLAVE_READ IS
    BEGIN
        WAIT UNTIL (falling_edge(CS));
        FOR i IN 23 DOWNTO 0 LOOP
            WAIT UNTIL (rising_edge(SCLK));
            SPI_RX(i) := MOSI;
        END LOOP;
    END SPI_SLAVE_READ;
    -----------------------------------------------------------
    PROCEDURE SPI_SLAVE_WRITE IS
    BEGIN
        WAIT UNTIL (falling_edge(CS));
        FOR i IN 23 DOWNTO 0 LOOP
                MISO <= SPI_TX(i);
            WAIT UNTIL (falling_edge(SCLK));
        END LOOP;
    END SPI_SLAVE_WRITE;
    -----------------------------------------------------------          
   
    BEGIN 
            SPI_SLAVE_READ;
            IF SPI_RX=X"BFFF00" THEN 
                SPI_SLAVE_READ;
                IF SPI_RX=X"000180" THEN 
                    SPI_SLAVE_READ;
                    IF SPI_RX=X"002000" THEN
                        SPI_SLAVE_READ;
                        IF SPI_RX=X"001401" THEN
                            WHILE(TRUE) LOOP
                                WAIT UNTIL (rising_edge(CNV)); 
                                BUSY <= '1';
                                WAIT FOR 300NS;
                                BUSY <= '0'; 
                                SPI_SLAVE_WRITE;
                                SPI_TX := std_logic_vector(unsigned(SPI_TX)+1);
                            END LOOP;
                        END IF;
                    END IF;
                END IF;
            END IF;
            

    END AD4030_BEHAVIOR;
    --===================================================================================




begin

    tb_CLOCK <= not tb_CLOCK after clk_period / 2;

    UUT: AD4030_FSM
        port map (
            DATA        =>      tb_DATA ,
            CLOCK       =>      tb_CLOCK,
            START       =>      tb_START,
            DRDY        =>      tb_DRDY ,
            RESET       =>      tb_RESET,
 
            MOSI        =>      tb_MOSI ,
            MISO        =>      tb_MISO ,
            SCLK        =>      tb_SCLK ,
            CS          =>      tb_CS   ,
            RST         =>      tb_RST  ,
            CNV         =>      tb_CNV  ,
            BUSY        =>      tb_BUSY 
        );

    HANDLE_BLOCK_PROC : process
    begin

        wait until (falling_edge(tb_CLOCK));
        wait until (falling_edge(tb_CLOCK));
        wait until (falling_edge(tb_CLOCK));
        tb_RESET <= '0';
        wait until (falling_edge(tb_CLOCK));
        tb_RESET <= '1';
        wait until (falling_edge(tb_CLOCK));
        wait until (falling_edge(tb_CLOCK));
        wait until (falling_edge(tb_CLOCK));
        wait until (falling_edge(tb_CLOCK));
        tb_START <= '1';
        wait;
            
    end process;


    AD4030_MODEL_PROC :process
    begin 
        AD4030_BEHAVIOR(tb_MISO, tb_MOSI, tb_SCLK, tb_CS, tb_RST, tb_CNV, tb_BUSY);
     end process;

     
end Behavioral;
