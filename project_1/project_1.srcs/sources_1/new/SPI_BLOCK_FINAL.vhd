library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity SPI_BLOCK_FINAL is
    GENERIC(clk_div  : INTEGER := 1); 
    PORT(
        tx_data : IN     STD_LOGIC_VECTOR(23 DOWNTO 0);         --data transmit    
        rx_data : OUT    STD_LOGIC_VECTOR(23 DOWNTO 0);         --data received
        clock   : IN     STD_LOGIC;                             --system clock  
        busy    : OUT    STD_LOGIC;                             --busy / data ready signal
        reset   : IN     STD_LOGIC;                             --asynchronous reset
        enable  : IN     STD_LOGIC;                             --initiate transaction
                                   
        mosi    : OUT    STD_LOGIC;                             --master out, slave in
        miso    : IN     STD_LOGIC;                             --master in, slave out
        sclk    : BUFFER STD_LOGIC;                             --spi clock
        cs      : OUT    STD_LOGIC                              --spi chip select
    );
end SPI_BLOCK_FINAL;

architecture Behavioral of SPI_BLOCK_FINAL is

    TYPE Tstate IS (idle, delay, clock0, clock1, compelete);
    SIGNAL state            : Tstate;
    SIGNAL S_rx_data        : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others=>'0');
    SIGNAL S_tx_data        : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others=>'0'); 
    SIGNAL S_miso           : STD_LOGIC; 
    SIGNAL ClockCounter     : integer := 0;
    SIGNAL index            : integer range 0 to 23 := 0;

begin

    process(clock, reset, enable)
    begin

        if(reset = '0') then    
            state <= idle;
            S_rx_data <= (others=>'0');
            S_tx_data <= (others=>'0');
            ClockCounter <= 0;
            sclk <= '0';
            index <= 0;
            busy <= '0';
            mosi <= 'Z';
            cs <= '1';

        elsif(clock'EVENT and clock = '1') then     
            case state is 

                when idle =>
                    if(enable = '1') then
                        S_tx_data <= tx_data;
                        S_rx_data <= (others=>'0');
                        state <= delay;
                        sclk <= '0';
                        busy <= '1';
                        ClockCounter <= 0;
                        index <= 23;
                    end if;

                when delay =>
                    cs <= '0';
                    mosi <= S_tx_data(index);
                    index <= index - 1;
                    state <= clock0;

                when clock0 =>
                    ClockCounter <= ClockCounter + 1;
                    if(ClockCounter = clk_div) then
                        sclk <= '1';
                        ClockCounter <= 0;
                        state <= clock1;
                    end if;

                when clock1 =>
                    ClockCounter <= ClockCounter + 1;
                    if(ClockCounter = clk_div) then
                        sclk <= '0';
                        state <= clock0;    
                        ClockCounter <= 0;
                        index <= index - 1;
                        if(index >= 0) then 
                            mosi <= S_tx_data(index);
                        else 
                            state <= compelete;
                        end if;
                        S_rx_data(index+1) <= S_miso;
                    end if;

                when compelete =>
                    state <= idle;
                    ClockCounter <= 0;
                    sclk <= '0';
                    index <= 0;
                    busy <= '0';
                    mosi <= 'Z';
                    rx_data <= S_rx_data;
                    cs <= '1';

            end case;
        end if;
    end process;

--    process(enable)
--    begin
--        if(enable'EVENT and enable = '1') then
--            S_tx_data <= tx_data;
--        end if;
--    end process;
        
    S_miso <= miso;

end Behavioral;
