library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AD4030_FSM is
    PORT(
            DATA    : OUT    STD_LOGIC_VECTOR(23 DOWNTO 0);     --24-bit data achived from adc convertion
            CLOCK   : IN     STD_LOGIC;                         --main clock   
            START   : IN     STD_LOGIC;                         --start of convert states  
            DRDY    : OUT    STD_LOGIC;                         --ready data to read DATA pins  
            RESET   : IN     STD_LOGIC;                         --reset the states and stop 
            ---------------------------                                                              
            MOSI    : OUT    STD_LOGIC;                         --MOSI to connect ADC  
            MISO    : IN     STD_LOGIC;                         --MISO to connect ADC  
            SCLK    : BUFFER STD_LOGIC;                         --SCLK to connect ADC   
            CS      : OUT    STD_LOGIC;                         --CS to connect ADC                
            RST     : OUT    STD_LOGIC;                         --RESET to connect ADC                
            CNV     : OUT    STD_LOGIC;                         --CNV to connect ADC                        
            BUSY    : IN     STD_LOGIC                          --BUSY to connect ADC                            
        );
end AD4030_FSM;

architecture Behavioral of AD4030_FSM is

    COMPONENT SPI_BLOCK_FINAL
    generic(clk_div  : INTEGER := 1); 
    PORT(
            tx_data : IN     STD_LOGIC_VECTOR(23 DOWNTO 0);     --data transmit
            rx_data : OUT    STD_LOGIC_VECTOR(23 DOWNTO 0);     --data received
            clock   : IN     STD_LOGIC;                         --system clock
            busy    : OUT    STD_LOGIC;                         --busy / data ready signal
            reset   : IN     STD_LOGIC;                         --asynchronous reset
            enable  : IN     STD_LOGIC;                         --initiate transaction
            ---------------------------
            mosi    : OUT    STD_LOGIC;                         --master out, slave in
            miso    : IN     STD_LOGIC;                         --master in, slave out
            sclk    : BUFFER STD_LOGIC;                         --spi clock
            cs      : OUT    STD_LOGIC                          --spi chip select
        );
    END COMPONENT;

    signal spi_reset     :    std_logic := '1';
    signal spi_enable    :    std_logic := '0';
    signal spi_tx_data   :    std_logic_vector(23 downto 0) := X"000000";
    signal spi_rx_data   :    std_logic_vector(23 downto 0) := X"000000";
    signal spi_busy      :    std_logic := '0';
------------------------------------------------------------------------------
    signal s_rst         :    std_logic := '1';
    signal s_cnv         :    std_logic := '0';
    signal s_busy        :    std_logic := '0';
------------------------------------------------------------------------------
    TYPE Tstate IS (
                        IDLE, 
                        REG_INIT_CMD, REG_SEND_CMD, CHK_SPIBUSY_CMD,                
                        REG_INIT_CFG_B, REG_SEND_CFG_B, CHK_SPIBUSY_CFG,
                        REG_INIT_MODES_SINGLE, REG_SEND_MODES_SINGLE, CHK_SPIBUSY_MODES,
                        REG_INIT_EXITCMD, REG_SEND_EXITCMD, CHK_SPIBUSY_EXITCMD,
                        START_CONVERSION, WAIT_FOR_BUSY, CHK_SPIBUSY_READ_DATA, READ_24BIT_DATA
                    );
    SIGNAL state         :    Tstate;
    signal s_start       :    std_logic := '0';
    signal s_reset       :    std_logic := '0';
    signal s_temp_data   :    std_logic_vector(23 downto 0) := X"000000";
    signal CycleCount    :    INTEGER := 0;

begin

    SPIBLOCK: SPI_BLOCK_FINAL
        generic map (1)
        port map (
            tx_data    =>       spi_tx_data,
            rx_data    =>       spi_rx_data,
            clock      =>       CLOCK,
            busy       =>       spi_busy,
            reset      =>       RESET,
            enable     =>       spi_enable,
            -------------------------------
            miso       =>       MISO,
            mosi       =>       MOSI,
            sclk       =>       SCLK,
            cs         =>       CS
        );

    process(CLOCK, s_reset, s_busy)
    begin

        if( s_reset = '0') then    
            state <= IDLE;
            s_rst <= '1';
            s_cnv <= '0';
            ------------------
            --spi_reset <= '1';
            ------------------
            DATA <= X"000000";
            DRDY <= '0';
            CycleCount <= 0;
        elsif(clock'EVENT and clock = '1') then     
            case state is 
            --____________________________
            --     Initiate States 
            --____________________________
            when IDLE =>
                    if(s_start = '1') then
                        state <= REG_INIT_CMD;    
                    end if;
            --____________________________
                when REG_INIT_CMD =>
                    spi_tx_data <= x"BFFF00";
                    state <= REG_SEND_CMD;         
            --____________________________
                when REG_SEND_CMD =>
                    spi_enable <= '1';
                    state <= CHK_SPIBUSY_CMD;  
            --____________________________
                when CHK_SPIBUSY_CMD => 
                    if(spi_busy = '1') then
                        state <= REG_INIT_CFG_B;
                    end if;          
            --____________________________
                when REG_INIT_CFG_B =>
                    spi_enable <= '0';
                    spi_tx_data <= x"000180";
                    if(spi_busy = '0') then
                        state <= REG_SEND_CFG_B;
                    end if;
            --____________________________
                when REG_SEND_CFG_B =>
                    spi_enable <= '1';
                    state <= CHK_SPIBUSY_CFG; 
            --____________________________
                when CHK_SPIBUSY_CFG => 
                if(spi_busy = '1') then
                    state <= REG_INIT_MODES_SINGLE;
                end if; 
            --____________________________
            when REG_INIT_MODES_SINGLE =>
                spi_enable <= '0';
                spi_tx_data <= x"002000";
                if(spi_busy = '0') then
                    state <= REG_SEND_MODES_SINGLE;
                end if;
            --____________________________
                when REG_SEND_MODES_SINGLE =>
                    spi_enable <= '1';
                    state <= CHK_SPIBUSY_MODES;
            --____________________________
                when CHK_SPIBUSY_MODES => 
                if(spi_busy = '1') then
                    state <= REG_INIT_EXITCMD;
                end if;
            --____________________________                
                when REG_INIT_EXITCMD =>
                spi_enable <= '0';
                spi_tx_data <= x"001401";
                if(spi_busy = '0') then
                    state <= REG_SEND_EXITCMD;
                end if;
            --____________________________
                when REG_SEND_EXITCMD =>
                    spi_enable <= '1';
                    state <= CHK_SPIBUSY_EXITCMD;
            --____________________________
                when CHK_SPIBUSY_EXITCMD => 
                if(spi_busy = '1') then
                    state <= START_CONVERSION;
                end if;
            --____________________________
            --  Conversion AND Read DATA    
            --____________________________
            when START_CONVERSION => 
                spi_tx_data <= x"000000";
                spi_enable <= '0';
                if(spi_busy = '0') then 
                    s_cnv <= '1';
                    if(s_busy = '1') then                     
                        state <= WAIT_FOR_BUSY;
                    end if;
                end if;
            --____________________________
            when WAIT_FOR_BUSY => 
                s_cnv <= '0';
                if(s_busy = '0') then
                    spi_enable <= '1';
                    if(spi_enable = '1') then
                        state <= CHK_SPIBUSY_READ_DATA;
                    end if;
                end if;
            --____________________________
            when CHK_SPIBUSY_READ_DATA => 
                spi_enable <= '0';
                if(spi_busy = '0') then
                    DRDY <= '0';
                    state <= READ_24BIT_DATA;
                end if;
            --____________________________
            when READ_24BIT_DATA => 
                if(s_busy = '0') then 
                    DATA <= spi_rx_data;
                    DRDY <= '1';
                    state <= START_CONVERSION;
                end if;
            --____________________________           
            end case;
        end if;
    end process;



    spi_reset <= RESET;
    RST <= s_rst;
    CNV <= s_cnv;
    s_busy <= BUSY;
    -----------------
    s_start <= START;
    s_reset <= RESET;

end Behavioral;
