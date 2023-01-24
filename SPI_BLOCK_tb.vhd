library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use std.textio.all;
use std.env.finish;

entity SPI_BLOCK_tb is
end SPI_BLOCK_tb;

architecture Behavioral of SPI_BLOCK_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;


    COMPONENT SPI_BLOCK_FINAL
    generic(clk_div  : INTEGER := 1); 
    PORT(
            tx_data : IN     STD_LOGIC_VECTOR(23 DOWNTO 0);      
            rx_data : OUT    STD_LOGIC_VECTOR(23 DOWNTO 0); --data received
            clock   : IN     STD_LOGIC;                             --system clock
            busy    : OUT    STD_LOGIC;                             --busy / data ready signal
            reset   : IN     STD_LOGIC;                             --asynchronous reset
            enable  : IN     STD_LOGIC;                             --initiate transaction
            mosi    : OUT    STD_LOGIC;                             --master out, slave in
            miso    : IN     STD_LOGIC;                             --master in, slave out
            sclk    : BUFFER STD_LOGIC;                             --spi clock
            cs      : OUT    STD_LOGIC
    );
    END COMPONENT;

    signal tb_clk       :    std_logic := '0';
    signal tb_reset     :    std_logic := '1';
    signal tb_enable    :    std_logic := '0';
    signal tb_tx_data   :    std_logic_vector(23 downto 0) := X"BFFF00";
    signal tb_rx_data   :    std_logic_vector(23 downto 0) := X"000000";
    signal tb_miso      :    std_logic := '0';
    signal tb_sclk      :    std_logic := '0';
    signal tb_cs        :    std_logic := '0';
    signal tb_mosi      :    std_logic := '0';
    signal tb_busy      :    std_logic := '0';
begin

    UUT: SPI_BLOCK_FINAL
        generic map (3)
        port map (
            tx_data    =>       tb_tx_data,
            rx_data    =>       tb_rx_data,
            clock      =>       tb_clk,
            busy       =>       tb_busy,
            reset      =>       tb_reset,
            enable     =>       tb_enable,
            miso       =>       tb_miso,
            mosi       =>       tb_mosi,
            sclk       =>       tb_sclk,
            cs         =>       tb_cs
        );

    tb_clk <= not tb_clk after clk_period / 2;

    tb_miso <= tb_mosi; 

    SEQUENCER_PROC : process
    begin

        wait until (falling_edge(tb_clk));
        wait until (falling_edge(tb_clk));
        wait until (falling_edge(tb_clk));
        tb_reset <= '0';
        wait until (falling_edge(tb_clk));
        tb_reset <= '1';
        wait until (falling_edge(tb_clk));
        wait until (falling_edge(tb_clk));
        wait until (falling_edge(tb_clk));
        wait until (falling_edge(tb_clk));
        tb_enable <= '1';
        wait until (falling_edge(tb_clk));
        tb_tx_data <= X"808080";
        --wait until (falling_edge(tb_busy));
        --wait until (falling_edge(tb_busy));
        --tb_enable <= '0';

        wait until (falling_edge(tb_clk));
        tb_enable <= '0';        

        wait;
         
    end process;

end architecture;

