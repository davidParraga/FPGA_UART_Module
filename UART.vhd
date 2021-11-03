----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:31:50 07/04/2019 
-- Design Name: 
-- Module Name:    UART - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART is
		Port (CLK : in std_logic;
				RESET : in std_logic;
				------------------------TRANSMISOR----------------------------
				TX_DATA :in std_logic_vector(7 downto 0);
				BTN_IN : in std_logic;
				TX_OUT : out std_logic;
				TX_READY : out std_logic;
				------------------------RECEPTOR------------------------------
				RX_in : in std_logic;
				RX_DATA : OUT std_logic_vector (7 downto 0);
				RX_NEWDATA : OUT std_logic);
		end UART;
	
architecture Behavioral of UART is
--------------------------------------------------------------
------------------------TRANSMISOR----------------------------
signal BTN : std_logic;
type mis_estados_1 is (cero , flanco , uno);
type mis_estados_2 is (idle , TX_inicio , TX_datos);
signal estado_actual_1 , estado_siguiente_1 : mis_estados_1;
signal estado_actual_2 , estado_siguiente_2 : mis_estados_2;
signal TX_START : std_logic;
signal cont_5209 : unsigned (12 downto 0);
signal ACTUALIZACION_TX : std_logic;
signal TSR : std_logic_vector (9 downto 0);
signal TX_nbit : unsigned (3 downto 0);
signal enable_transmitter_shift_register : std_logic;
signal enable_transmitter_counter : std_logic;
signal enable_tx_ready : std_logic;
signal enable_baud_rate_counter : std_logic;
signal enable_carga_tx_data : std_logic;

--------------------------------------------------------------
------------------------RECEPTOR------------------------------
signal cont_5209_2 : unsigned (12 downto 0);
signal RX_nbits : unsigned (3 downto 0);
signal ACTUALIZACION_RX :std_logic;
signal RSR : std_logic_vector (7 downto 0);
type mis_estados_3 is (idle , Rx_inicio , Rx_datos , Rx_fin);
signal estado_actual_3 , estado_siguiente_3 : mis_estados_3;
signal enable_receiver_shift_register : std_logic;
signal enable_receiver_counter : std_logic;
signal enable_baud_rate_counter_receiver : std_logic;
signal enable_carga_rx_newdata : std_logic;
--------------------------------------------------------------

begin

--------------------------------------------------------------
------------------------TRANSMISOR----------------------------

process (CLK , RESET)  				--regBTN
	begin
			if (reset = '1') THEN
				BTN <= '0';
			elsif (CLK'EVENT AND CLK = '1') THEN
				BTN <= BTN_IN;
			end if;
	end process;
	
process (CLK , RESET)				--BaudRadeGenerator
begin
		if (RESET = '1') then
			ACTUALIZACION_TX <= '0'; 
			cont_5209 <= (others => '0');
		elsif(CLK'EVENT AND CLK = '1') then
				if (enable_baud_rate_counter = '1') then 
					if (cont_5209 < 5209) then 
						cont_5209 <= cont_5209 + 1;
						ACTUALIZACION_TX <= '0';
					else
						cont_5209 <= (others => '0');
						ACTUALIZACION_TX <= '1';
					end if;
				end if;
		end if;
end process;


		
process (CLK ,RESET)				--Transmitter Shift Register
begin
	if (RESET = '1') then
			TSR <= (others => '0');
	elsif (CLK'EVENT AND CLK = '1') then
			if (enable_carga_tx_data = '1') then
						TSR <= '1' & TX_DATA & '0';
			elsif (enable_transmitter_shift_register = '1') then
					if (ACTUALIZACION_TX = '1') then	
						TSR <= '1' & TSR (9 downto 1);
					end if;
			end if;
	end if;
end process;

TX_OUT <= TSR (0);



process (CLK , RESET)			--Transmiter counter
begin	
	if (RESET ='1') then 
		TX_nbit <= (others => '0');
	elsif (CLK'EVENT AND CLK = '1') then
			if (enable_transmitter_counter = '1') then 
					if (ACTUALIZACION_TX = '1') then
							if (TX_nbit < 10) then
							TX_nbit <= TX_nbit +1;
							else
							TX_nbit <= (others => '0');
							end if;
					end if;
			end if;
	end if;
end process;

process (CLK , RESET)							--regTXready
begin
	if(RESET = '1') then
		TX_READY <= '1';
	elsif (CLK'EVENT AND CLK = '1') then
		if(enable_tx_ready = '1') then
			TX_READY <= '1';
		else
			TX_READY <= '0';
		end if;
	end if;
end process;


----------------------------MÁQUINA DE ESTADO------------------------------
----------------------DETECTOR DE FLANCO ASCENDENTE------------------------

process (CLK , RESET)									--Proceso_Estado_1
begin
		if (reset = '1') then
			estado_actual_1 <= cero;
		elsif (CLK'event AND CLK = '1') then
			estado_actual_1 <= estado_siguiente_1;
		end if;
end process;

process (estado_actual_1)								--Poceso_de_Salidas_1
begin 
	case estado_actual_1 is
		when cero => TX_START <= '0';
		when flanco => TX_START <= '1';
		when uno => TX_START <= '0';
	end case;
end process;


process (estado_actual_1 , BTN)						--Proceso_Estado_Siguiente_1
begin
	case estado_actual_1 is
		when cero => if (BTN = '1') then 
							estado_siguiente_1 <= flanco;
						 else 
							estado_siguiente_1 <= cero;
						 end if;
	
		when flanco => if (BTN = '1') then
							estado_siguiente_1 <= uno;
							else
							estado_siguiente_1 <= cero;
							end if;
							
			when uno => if(BTN = '1') then 
							estado_siguiente_1 <= uno;
						else
							estado_siguiente_1 <= cero;
						end if;
	end case;						
end process;


	
----------------------------MÁQUINA DE ESTADO----------------------------
-------------------------CONTROL DE TRANSMISIÓN--------------------------

process (CLK , RESET)											--Proceso_Estado_2
begin
		if (reset = '1') then
			estado_actual_2 <= idle;
		elsif (CLK'event AND CLK ='1') then
			estado_actual_2 <= estado_siguiente_2;
		end if;
end process;

process (estado_actual_2)												--Proceso_de_Salidas_2
begin
	case estado_actual_2 is
		when idle => enable_baud_rate_counter <= '0';
						 enable_transmitter_shift_register <= '0';
						 enable_transmitter_counter <= '0';
						 enable_tx_ready <= '1';
						 enable_carga_tx_data <= '0';
		when TX_inicio => enable_baud_rate_counter <= '0';
								enable_transmitter_shift_register <= '1';
								enable_transmitter_counter <= '1';
								enable_tx_ready <= '0';
								enable_carga_tx_data <= '1';
		when TX_datos =>  enable_baud_rate_counter <= '1';
								enable_transmitter_shift_register <= '1';
								enable_transmitter_counter <= '1';
								enable_tx_ready <= '0';
								enable_carga_tx_data <= '0';
	end case;
end process;
								
process (estado_actual_2 , BTN , TX_nbit , TX_START)					--Proceso_Estado_Siguiente_2
	begin
	 case estado_actual_2 is
		when idle => if (TX_START = '0') then
								estado_siguiente_2 <= idle;
						else
								estado_siguiente_2 <= TX_inicio;		
						end if;
		when TX_inicio => estado_siguiente_2 <= TX_datos;
		when TX_datos => 	if (TX_nbit < 10) then
									estado_siguiente_2 <= TX_datos;
								else 
									estado_siguiente_2 <= idle;
								end if;
	end case;
end process;

--------------------------------------------------------------
--------------------------RECEPTOR----------------------------


---------------------------------------------------------------
------------MÁQUINA DE ESTADOS CONTROL RECEPCIÓN---------------

process (clk , reset)
	begin
		if (reset = '1') then
			estado_actual_3 <= idle;
		elsif (clk'event AND clk = '1') then
			estado_actual_3 <= estado_siguiente_3;
		end if;
end process;

process (estado_actual_3)
	begin
		case estado_actual_3 is
			when idle => enable_baud_rate_counter_receiver <= '0';
							 enable_receiver_shift_register <= '0';
							 enable_receiver_counter <= '0';
							 enable_carga_rx_newdata <= '0';
							 
			when RX_inicio =>  enable_baud_rate_counter_receiver <= '1';
									 enable_receiver_shift_register <= '0';
									 enable_receiver_counter <= '1';
									 enable_carga_rx_newdata <= '0';

									
			when RX_datos =>  enable_baud_rate_counter_receiver <= '1';
									enable_receiver_shift_register <= '1';
									enable_receiver_counter <= '1';
									enable_carga_rx_newdata <= '0';

									
			when RX_fin	  =>  enable_baud_rate_counter_receiver <= '0';
									enable_receiver_shift_register <= '0';
									enable_receiver_counter <= '0';
									enable_carga_rx_newdata <= '1';
	  end case;
end process;
			
	

process (estado_actual_3 , RX_IN , RX_nbits)
	begin
		case estado_actual_3 is
			when idle =>  if (RX_IN = '0') then 
									estado_siguiente_3 <= RX_inicio;
							  else
									estado_siguiente_3 <= idle;
							  end if;
			when RX_inicio => estado_siguiente_3 <= RX_datos;
			when RX_datos => if (RX_nbits < 9) then
										estado_siguiente_3 <= RX_fin;
									else
										estado_siguiente_3 <= RX_datos;
									end if;
			when RX_fin =>	estado_siguiente_3 <= idle;
		end case;
end process;

process (CLK , RESET)										--Receiver baud rate generator
begin
	if (RESET = '1') then
		cont_5209_2 <= (others => '0');
	elsif (CLK'EVENT AND CLK = '1') then
			if(enable_baud_rate_counter_receiver = '1') then
					if (cont_5209_2 < 5209) then
						cont_5209_2 <= cont_5209_2 + 1;
						ACTUALIZACION_RX <= '0';
					else
						cont_5209_2 <= (others => '0');
						ACTUALIZACION_RX <= '1';
					end if;
			end if;
	end if;
end process;
	
process (CLK , RESET)									--Receiver Shift Register
begin
if (RESET = '1') then
	RSR <= (others => '0');
elsif (CLK'EVENT AND CLK = '1') then
	if (enable_receiver_shift_register = '1') then
		if (ACTUALIZACION_RX = '1') then
					RSR <= RX_in & RSR (7 downto 1);
		end if;
	end if;
end if;
end process;
				
process (CLK , RESET)								--regRX
begin
	if (RESET = '1') then
		RX_DATA <= (others => '0');
	elsif (CLK'EVENT AND CLK = '1') then
		if (enable_carga_rx_newdata <= '1') then
			if (ACTUALIZACION_RX = '1') then
				RX_DATA <= RSR;
			end if;
		end if;
	end if;
end process;
				

process (CLK , RESET)    							--regRX_newdata
begin
	if (RESET = '1') then
		RX_NEWDATA <= '0';
	elsif (CLK'EVENT AND CLK = '1') then
		if (enable_carga_rx_newdata = '1') then
			RX_NEWDATA <= '0';
		else
			RX_NEWDATA <= '1';
		end if;
	end if;
end process;
			
			
			
process (CLK , RESET)									--Receiver Counter Register
begin
	if (RESET = '1') then
		RX_nbits <= (others => '0');
	elsif (CLK'EVENT AND CLK = '1') then
		if (enable_receiver_counter = '1') then
			if (ACTUALIZACION_RX = '1') then
				if (RX_nbits < 9) then
					RX_nbits <= RX_nbits + 1;
				else
					RX_nbits <= (others => '0');
				end if;
			end if;
		end if;
	end if;
end process;



end Behavioral;