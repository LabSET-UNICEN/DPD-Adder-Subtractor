-- Este core efectúa la suma/resta con operandos IEEE 2008
-- Versión de suma/resta que utiliza dígito de Guarda, Dígito de redondeo y bit stick


-- Tranaja con los operandos ya decodificados 
-- <sa>, <qa> y <ma>; correspondiente a signo, exponente y 
-- mantisa de operando <a>

-- <sb>, <qb> y <mb>; correspondiente a signo, exponente y 
-- mantisa de operando <a>
-- No hay manejo de underflow, overflog, NaN, etc


-- Trabaja con operandos de entrada <a> y <b> codificados y resultado <r> tambien codificado
-- Produce ademas diferentes banderas: overflow, invalid, inexact y underflow

-- Este módulo trabaja con tres formatos
-- decimal32: Nexp=8 y P=7 
-- decimal64: Nexp=10 y P=16 
-- decimal128:  Nexp=14 y P=34 

-- Donde 
--  N representa la cantidad de bits de los operandos
--  NExp la cantidad de bits que posee el exponente
--  P la precisión deimal de la mantisa
-- Tanto NExp como P son datos que usan los compontes de mas bajo nivel

-- Donde 
-- TypeRound es la técnica de redondeo

-- Para TypeRound cuando es
-- 0 => RoundTowardPositive
-- 1 => RoundTowardNegative
-- 2 => RoundTowardZero
-- 3 => RoundTiesToAway
-- 4 => RoundTiesToEven

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.my_package.all;

library UNISIM;
use UNISIM.VComponents.all;

entity AddSubDFP_GD is
	 generic (TypeRound: integer:= 4;
				NExp: integer:= 10;
				P: integer:=16);
				
    Port ( op : in  std_logic;
           sa, sb: in std_logic;
           qa, qb : in  std_logic_vector (NExp-1 downto 0);
           ma, mb : in  std_logic_vector (4*P-1 downto 0);
		   sr: out std_logic;
           qr : out  std_logic_vector (NExp-1 downto 0);
--mo_g, mo_l : out  std_logic_vector (4*(P+3)-1 downto 0);
           mr : out  std_logic_vector (4*P-1 downto 0));
end AddSubDFP_GD;

architecture Behavioral of AddSubDFP_GD is


    
    component LeadingZeros is
        generic (P: integer:=16);
        Port ( a : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
                 c : out  STD_LOGIC_VECTOR (log2sup(P+1)-1 downto 0));
    end component;
    
    
    component AS_SVA_CB_I is
            generic (TAddSub: integer:= 0; N : integer:=7);  
            port ( 
                  op : in  std_logic;
                  s_a : in  std_logic;
               a : in  std_logic_vector (4*N-1 downto 0);
                  s_b : in  std_logic;
               b : in  std_logic_vector (4*N-1 downto 0);
               co: out std_logic;
                  s_r : out std_logic;
               r : out std_logic_vector (4*N-1 downto 0));
    end component;
	
	
    component adder_BCD_L6 
           Generic (TAdd: integer:= 1; NDigit : integer:=7);    
            Port ( 
                    a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
                   cin : in  STD_LOGIC;
                   cout : out  STD_LOGIC;
                   s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
    end component;
	
	
	signal s_g, s_l: std_logic; 
	-- signo de operando con mayor y menor exponente.

    signal q_g: std_logic_vector (NExp-1 downto 0); 
    -- exponentes corrspondientes a mayor
         
	signal m_g, m_l: std_logic_vector (4*P-1 downto 0); 
    -- matisas en complemento a la base del operando con mayor y menor exponente
    

    signal flg_sw: std_logic; -- flag qe indica si se realiza el swap entre los operandos
    
    signal q_diff_abs: std_logic_vector(NExp-1 downto 0);
    -- posee la diferencia en valor abcoluto entre qa-qb. El resultado no posee la frntera
         

    signal m_g_ext, m_l_ext : std_logic_vector (4*(P+3)-1 downto 0);
    -- las dos mantisas de P+3 dígitos listas para operar, poseen GD, RD y Stick bit
    
    signal count_lz: std_logic_vector(log2sup(P+1)-1 downto 0);
    -- posee la cantidad de ceros iniciales del operando con mayor exponente
    
    -- señales involucradas en la resta de la diferencia de expoenntes y cantidad de zeros de operando con mayor exponente    
    signal zeros_lz: std_logic_vector(Nexp-log2sup(P+1)-1 downto 0);
    signal oper_count_lz: std_logic_vector(NExp-1 downto 0);
    
    
    signal oper_diff: std_logic_vector(NExp-1 downto 0);     

    signal val_sh_left : std_logic_vector(log2sup(P+1)-1 downto 0);
    -- es el valor que se desplaza a izquierda el operando de mayor exponente
    
    signal val_sh_right : std_logic_vector(NExp-1 downto 0);
    -- es el valor que se desplaza a derecha el operando de manor exponente
    -- la dimensión debería ser menor porque satura en P*2
    
    signal eval_sticky: std_logic_vector(4*p-1 downto 0);
    -- señal que se utiliza para saber si la "cola", lo que se descarta posee un valor diferente de 0.
    -- usado para el sticky bit

    signal stb:std_logic;
    -- representa el sticky bit

    signal s_inv: std_logic; -- indica si debo invertir el signo del resultado que me arrojo el AddSub SVA fixed
    signal s_r_fix: std_logic; -- signo del resultado del AddSub SVA fixed
    
    signal m_r_fix: std_logic_vector(4*(P+3)-1 downto 0);
    --signal m_r_fix: std_logic_vector(4*(P+3)-1 downto 0); 
    -- señal que representa la salida en SVA del del AddSub del SVA fixed


    signal val_sub_zeros: std_logic_vector(NExp-log2sup(P+1)-1 downto 0);
    -- para armar el valor a restar al exponente del resultado. En realidad es una constante
    signal val_sub_exp: std_logic_vector(NExp-1 downto 0);
    -- corresponde al valor a restar en el ajuste del exponente del resultado

    signal cy_add: std_logic;
    -- indica cuando ocurres acarreo luego de la suma/resta
    
    signal m_r_pre_rd: std_logic_vector(4*(P+2)-1 downto 0);
    -- representa el resultado a considerar cuando ocurre el redondeo
    
    signal tmp_rd : std_logic_vector(19 downto 0);
    -- señal de 5 dígitos BCD usada pos la unidad de redondeo para establecer si sumar o no sumar uno a mantisa 
    
    signal nequal: std_logic; 
        -- usado por uniad de redondeo
        
    
    signal oper_zero_rd: std_logic_vector(4*P-1 downto 0); 
    signal oper_rd: std_logic; -- indica si se debe sumar uno en el caso de redondear hacia arriba
    signal cy_add_rd: std_logic; -- indica si hubo acarreo al sumar uno en el redondeo
    
    signal m_r_rd: std_logic_vector(4*P-1 downto 0);
    -- representa el resultado luego del redondeo
    
  
    signal q_pre: std_logic_vector(NExp-1 downto 0);
  -- resultado parcial de operacion que determina el exponente del resultado

    signal gr_a_b : std_logic; -- señal que indica si el exponente a es mayor al b

begin


    gr_a_b <= '1' when (qa > qb) else '0';
 
    
    -- genera el operando que posee mayor exponente
    s_g <= sa when (gr_a_b = '1') else sb;
    q_g <= qa when (gr_a_b = '1') else qb; 
    m_g <= ma when (gr_a_b = '1') else mb;
        
   -- genera el operando que posee mayor exponente
    s_l <= sb when (gr_a_b = '1') else sa;
    m_l <= mb when (gr_a_b = '1') else ma;
    
    -- flag que indica que se realizó swwap. Es innecesario pero simplifica el código en legibilidad
    -- lo elimina igual el sintetizador
    flg_sw <= not gr_a_b;
         
-- Fin de tratamiento de operandos para empezar a trabajar                  
	
	q_diff_abs <= (qa-qb) when (gr_a_b='1') else (qb-qa);
	

-- ========= 
-- detección de zeros iniciales en operando con exponente mayor m_g
-- armado de las mantisas en base a diferencia de exponente

    E_lz: LeadingZeros generic map (P => P)
                    Port map (a =>  m_g,  c => count_lz);
                
 
    zeros_lz <= (others => '0');
    oper_count_lz <= zeros_lz&count_lz;
    oper_diff <= q_diff_abs - oper_count_lz;
    
    val_sh_left <= q_diff_abs(log2sup(P+1)-1 downto 0) when (q_diff_abs<oper_count_lz) else count_lz;
    
    val_sh_right <=  (others => '0') when (q_diff_abs<oper_count_lz) else oper_diff;
     
    -- después veo el tema del tamaño aunque igual lo descarta en síntesis a lo sobrante
       
    sh_lz_P7: if P=7 generate
        m_g_ext <= (m_g&(x"000")) when (val_sh_left="000") else
                   (m_g(23 downto 0)&(x"0000")) when (val_sh_left="001") else
                   (m_g(19 downto 0)&(x"00000")) when (val_sh_left="010") else
                   (m_g(15 downto 0)&(x"000000")) when (val_sh_left="011") else
                   (m_g(11 downto 0)&(x"0000000")) when (val_sh_left="100") else
                   (m_g(7 downto 0)&(x"00000000")) when (val_sh_left="101") else
                   (m_g(3 downto 0)&(x"000000000")) when (val_sh_left="110") else
                   (others => '0');
                   
        -- manejo los P+2 más significativos
        m_l_ext(4*P+11 downto 4) <= (m_l&(x"00")) when (val_sh_right="00000000") else
                   ((x"0")&m_l&(x"0")) when (val_sh_right="00000001") else
                   ((x"00")&m_l) when (val_sh_right="00000010") else
                   ((x"000")&m_l(27 downto 4)) when (val_sh_right="00000011") else
                   ((x"0000")&m_l(27 downto 8)) when (val_sh_right="00000100") else
                   ((x"00000")&m_l(27 downto 12)) when (val_sh_right="00000101") else
                   ((x"000000")&m_l(27 downto 16)) when (val_sh_right="00000110") else
                   ((x"0000000")&m_l(27 downto 20)) when (val_sh_right="00000111") else
                   ((x"00000000")&m_l(27 downto 24)) when (val_sh_right="00001000") else
                   (others => '0');  -- (val_sh_right="00001001") else P+2
                   
                   
        eval_sticky <=  (m_l(3 downto 0)&(x"000000")) when (val_sh_right="0000000011") else
                       (m_l(7 downto 0)&(x"00000")) when (val_sh_right="0000000100") else
                       (m_l(11 downto 0)&(x"0000")) when (val_sh_right="0000000101") else
                       (m_l(15 downto 0)&(x"000")) when (val_sh_right="0000000110") else
                       (m_l(19 downto 0)&(x"00")) when (val_sh_right="0000000111") else
                       (m_l(23 downto 0)&(x"0")) when (val_sh_right="0000001000") else
                       (m_l(27 downto 0));-- when (val_sh_right="0000001001") else
                       --(others => '0'); -- cuando Valsh_rigth = 0, 1, 2, o >P+2
    
    
        stb <= '0' when (eval_sticky= x"0000000") else '1';                   
        
         
                       
    end generate;

    sh_lz_P16: if P=16 generate
            m_g_ext <= (m_g&(x"000")) when (val_sh_left="00000") else
                   (m_g(59 downto 0)&(x"0000")) when (val_sh_left="00001") else
                   (m_g(55 downto 0)&(x"00000")) when (val_sh_left="00010") else
                   (m_g(51 downto 0)&(x"000000")) when (val_sh_left="00011") else
                   (m_g(47 downto 0)&(x"0000000")) when (val_sh_left="00100") else
                   (m_g(43 downto 0)&(x"00000000")) when (val_sh_left="00101") else
                   (m_g(39 downto 0)&(x"000000000")) when (val_sh_left="00110") else
                   (m_g(35 downto 0)&(x"0000000000")) when (val_sh_left="00111") else
                   (m_g(31 downto 0)&(x"00000000000")) when (val_sh_left="01000") else
                   (m_g(27 downto 0)&(x"000000000000")) when (val_sh_left="01001") else
                   (m_g(23 downto 0)&(x"0000000000000")) when (val_sh_left="01010") else
                   (m_g(19 downto 0)&(x"00000000000000")) when (val_sh_left="01011") else
                   (m_g(15 downto 0)&(x"000000000000000")) when (val_sh_left="01100") else
                   (m_g(11 downto 0)&(x"0000000000000000")) when (val_sh_left="01101") else
                   (m_g(7 downto 0)&(x"00000000000000000")) when (val_sh_left="01110") else
                   (m_g(3 downto 0)&(x"000000000000000000")) when (val_sh_left="01111") else
                   (others => '0');
            
            -- manejo los P+2 más significativos 
            m_l_ext(4*P+11 downto 4) <= 
                    (m_l&(x"00")) when (val_sh_right="0000000000") else
                    ((x"0")&m_l&(x"0")) when (val_sh_right="0000000001") else
                    ((x"00")&m_l) when (val_sh_right="0000000010") else
                    ((x"000")&m_l(63 downto 4)) when (val_sh_right="0000000011") else
                    ((x"0000")&m_l(63 downto 8)) when (val_sh_right="0000000100") else
                    ((x"00000")&m_l(63 downto 12)) when (val_sh_right="0000000101") else
                    ((x"000000")&m_l(63 downto 16)) when (val_sh_right="0000000110") else
                    ((x"0000000")&m_l(63 downto 20)) when (val_sh_right="0000000111") else
                    ((x"00000000")&m_l(63 downto 24)) when (val_sh_right="0000001000") else
                    ((x"000000000")&m_l(63 downto 28)) when (val_sh_right="0000001001") else 
                    ((x"0000000000")&m_l(63 downto 32)) when (val_sh_right="0000001010") else
                    ((x"00000000000")&m_l(63 downto 36)) when (val_sh_right="0000001011") else
                    ((x"000000000000")&m_l(63 downto 40)) when (val_sh_right="0000001100") else                    
                    ((x"0000000000000")&m_l(63 downto 44)) when (val_sh_right="0000001101") else 
                    ((x"00000000000000")&m_l(63 downto 48)) when (val_sh_right="0000001110") else
                    ((x"000000000000000")&m_l(63 downto 52)) when (val_sh_right="00000001111") else
                    ((x"0000000000000000")&m_l(63 downto 56)) when (val_sh_right="0000010000") else                    
                    ((x"00000000000000000")&m_l(63 downto 60)) when (val_sh_right="00000010001") else
                    ((x"000000000000000000")); -- (val_sh_right="0000010010") P+2                    
            

            eval_sticky <=  (m_l(3 downto 0)&(x"000000000000000")) when (val_sh_right="0000000011") else
                            (m_l(7 downto 0)&(x"00000000000000")) when (val_sh_right="0000000100") else
                            (m_l(11 downto 0)&(x"0000000000000")) when (val_sh_right="0000000101") else
                            (m_l(15 downto 0)&(x"000000000000")) when (val_sh_right="0000000110") else
                            (m_l(19 downto 0)&(x"00000000000")) when (val_sh_right="0000000111") else
                            (m_l(23 downto 0)&(x"0000000000")) when (val_sh_right="0000001000") else
                            (m_l(27 downto 0)&(x"000000000")) when (val_sh_right="0000001001") else
                            (m_l(31 downto 0)&(x"00000000")) when (val_sh_right="0000001010") else
                            (m_l(35 downto 0)&(x"0000000")) when (val_sh_right="0000001011") else
                            (m_l(39 downto 0)&(x"000000")) when (val_sh_right="0000001100") else
                            (m_l(43 downto 0)&(x"00000")) when (val_sh_right="0000001101") else
                            (m_l(47 downto 0)&(x"0000")) when (val_sh_right="0000001110") else
                            (m_l(51 downto 0)&(x"000")) when (val_sh_right="0000001111") else
                            (m_l(55 downto 0)&(x"00")) when (val_sh_right="0000010000") else
                            (m_l(59 downto 0)&(x"0")) when (val_sh_right="0000010001") else
                            m_l(63 downto 0);-- when (val_sh_right="0000010010") else
                            --(others => '0'); -- cuando Valsh_rigth = 0, 1, 2, o >P+2
                
                
            stb <= '0' when (eval_sticky= x"0000000000000000") else '1';     
                          
                  
    end generate;


    sh_lz_P34: if P=34 generate
        m_g_ext <= (m_g&(x"000")) when (val_sh_left="000000") else
                   (m_g(131 downto 0)&(x"0000")) when (val_sh_left="000001") else
                   (m_g(127 downto 0)&(x"00000")) when (val_sh_left="000010") else
                   (m_g(123 downto 0)&(x"000000")) when (val_sh_left="000011") else
                   (m_g(119 downto 0)&(x"0000000")) when (val_sh_left="000100") else
                   (m_g(115 downto 0)&(x"00000000")) when (val_sh_left="000101") else
                   (m_g(111 downto 0)&(x"000000000")) when (val_sh_left="000110") else
                   (m_g(107 downto 0)&(x"0000000000")) when (val_sh_left="000111") else
                   (m_g(103 downto 0)&(x"00000000000")) when (val_sh_left="001000") else
                   (m_g(99 downto 0)&(x"000000000000")) when (val_sh_left="001001") else
                   (m_g(95 downto 0)&(x"0000000000000")) when (val_sh_left="001010") else
                   (m_g(91 downto 0)&(x"00000000000000")) when (val_sh_left="001011") else
                   (m_g(87 downto 0)&(x"000000000000000")) when (val_sh_left="001100") else
                   (m_g(83 downto 0)&(x"0000000000000000")) when (val_sh_left="001101") else
                   (m_g(79 downto 0)&(x"00000000000000000")) when (val_sh_left="001110") else
                   (m_g(75 downto 0)&(x"000000000000000000")) when (val_sh_left="001111") else
                   (m_g(71 downto 0)&(x"0000000000000000000")) when (val_sh_left="010000") else
                   (m_g(67 downto 0)&(x"00000000000000000000")) when (val_sh_left="010001") else
                   (m_g(63 downto 0)&(x"000000000000000000000")) when (val_sh_left="010010") else
                   (m_g(59 downto 0)&(x"0000000000000000000000")) when (val_sh_left="010011") else
                   (m_g(55 downto 0)&(x"00000000000000000000000")) when (val_sh_left="010100") else
                   (m_g(51 downto 0)&(x"000000000000000000000000")) when (val_sh_left="010101") else
                   (m_g(47 downto 0)&(x"0000000000000000000000000")) when (val_sh_left="010110") else
                   (m_g(43 downto 0)&(x"00000000000000000000000000")) when (val_sh_left="010111") else
                   (m_g(39 downto 0)&(x"000000000000000000000000000")) when (val_sh_left="011000") else
                   (m_g(35 downto 0)&(x"0000000000000000000000000000")) when (val_sh_left="011001") else
                   (m_g(31 downto 0)&(x"00000000000000000000000000000")) when (val_sh_left="011010") else
                   (m_g(27 downto 0)&(x"000000000000000000000000000000")) when (val_sh_left="011011") else
                   (m_g(23 downto 0)&(x"0000000000000000000000000000000")) when (val_sh_left="011100") else
                   (m_g(19 downto 0)&(x"00000000000000000000000000000000")) when (val_sh_left="011101") else
                   (m_g(15 downto 0)&(x"000000000000000000000000000000000")) when (val_sh_left="011110") else
                   (m_g(11 downto 0)&(x"0000000000000000000000000000000000")) when (val_sh_left="011111") else
                   (m_g(7 downto 0)&(x"00000000000000000000000000000000000")) when (val_sh_left="100000") else
                   (m_g(3 downto 0)&(x"000000000000000000000000000000000000")) when (val_sh_left="100001") else
                   (others => '0');


          m_l_ext(4*P+11 downto 4) <= 
                    (m_l&(x"00")) when (val_sh_right="00000000000000") else
                    ((x"0")&m_l&(x"0")) when (val_sh_right="00000000000001") else
                    ((x"00")&m_l) when (val_sh_right="00000000000010") else
                    ((x"000")&m_l(135 downto 4)) when (val_sh_right="00000000000011") else
                    ((x"0000")&m_l(135 downto 8)) when (val_sh_right="00000000000100") else
                    ((x"00000")&m_l(135 downto 12)) when (val_sh_right="00000000000101") else
                    ((x"000000")&m_l(135 downto 16)) when (val_sh_right="00000000000110") else
                    ((x"0000000")&m_l(135 downto 20)) when (val_sh_right="00000000000111") else
                    ((x"00000000")&m_l(135 downto 24)) when (val_sh_right="00000000001000") else
                    ((x"000000000")&m_l(135 downto 28)) when (val_sh_right="00000000001001") else 
                    ((x"0000000000")&m_l(135 downto 32)) when (val_sh_right="00000000001010") else
                    ((x"00000000000")&m_l(135 downto 36)) when (val_sh_right="00000000001011") else
                    ((x"000000000000")&m_l(135 downto 40)) when (val_sh_right="00000000001100") else                    
                    ((x"0000000000000")&m_l(135 downto 44)) when (val_sh_right="00000000001101") else 
                    ((x"00000000000000")&m_l(135 downto 48)) when (val_sh_right="00000000001110") else
                    ((x"000000000000000")&m_l(135 downto 52)) when (val_sh_right="00000000001111") else
                    ((x"0000000000000000")&m_l(135 downto 56)) when (val_sh_right="00000000010000") else                    
                    ((x"00000000000000000")&m_l(135 downto 60)) when (val_sh_right="00000000010001") else
                    ((x"000000000000000000")&m_l(135 downto 64)) when (val_sh_right="00000000010010") else                    
                    ((x"0000000000000000000")&m_l(135 downto 68)) when (val_sh_right="00000000010011") else
                    ((x"00000000000000000000")&m_l(135 downto 72)) when (val_sh_right="00000000010100") else                    
                    ((x"000000000000000000000")&m_l(135 downto 76)) when (val_sh_right="00000000010101") else
                    ((x"0000000000000000000000")&m_l(135 downto 80)) when (val_sh_right="00000000010110") else                   
                    ((x"00000000000000000000000")&m_l(135 downto 84)) when (val_sh_right="00000000010111") else
                    ((x"000000000000000000000000")&m_l(135 downto 88)) when (val_sh_right="00000000011000") else                    
                    ((x"0000000000000000000000000")&m_l(135 downto 92)) when (val_sh_right="00000000011001") else
                    ((x"00000000000000000000000000")&m_l(135 downto 96)) when (val_sh_right="00000000011010") else                   
                    ((x"000000000000000000000000000")&m_l(135 downto 100)) when (val_sh_right="00000000011011") else
                    ((x"0000000000000000000000000000")&m_l(135 downto 104)) when (val_sh_right="00000000011100") else                    
                    ((x"00000000000000000000000000000")&m_l(135 downto 108)) when (val_sh_right="00000000011101") else
                    ((x"000000000000000000000000000000")&m_l(135 downto 112)) when (val_sh_right="00000000011110") else                   
                    ((x"0000000000000000000000000000000")&m_l(135 downto 116)) when (val_sh_right="00000000011111") else
                    ((x"00000000000000000000000000000000")&m_l(135 downto 120)) when (val_sh_right="00000000100000") else                    
                    ((x"000000000000000000000000000000000")&m_l(135 downto 124)) when (val_sh_right="00000000100001") else
                    ((x"0000000000000000000000000000000000")&m_l(135 downto 128)) when (val_sh_right="00000000100010") else                   
                    ((x"00000000000000000000000000000000000")&m_l(135 downto 132)) when (val_sh_right="00000000100011") else
                    (x"000000000000000000000000000000000000"); -- (val_sh_right="00000000100110") P+2                                                           



            eval_sticky <=  (m_l(3 downto 0)&(x"000000000000000000000000000000000")) when (val_sh_right="00000000000011") else
                            (m_l(7 downto 0)&(x"00000000000000000000000000000000")) when (val_sh_right="00000000000100") else
                            (m_l(11 downto 0)&(x"0000000000000000000000000000000")) when (val_sh_right="00000000000101") else
                            (m_l(15 downto 0)&(x"000000000000000000000000000000")) when (val_sh_right="00000000000110") else
                            (m_l(19 downto 0)&(x"00000000000000000000000000000")) when (val_sh_right="00000000000111") else
                            (m_l(23 downto 0)&(x"0000000000000000000000000000")) when (val_sh_right="00000000001000") else
                            (m_l(27 downto 0)&(x"000000000000000000000000000")) when (val_sh_right="00000000001001") else
                            (m_l(31 downto 0)&(x"00000000000000000000000000")) when (val_sh_right="00000000001010") else
                            (m_l(35 downto 0)&(x"0000000000000000000000000")) when (val_sh_right="00000000001011") else
                            (m_l(39 downto 0)&(x"000000000000000000000000")) when (val_sh_right="00000000001100") else
                            (m_l(43 downto 0)&(x"00000000000000000000000")) when (val_sh_right="00000000001101") else
                            (m_l(47 downto 0)&(x"0000000000000000000000")) when (val_sh_right="00000000001110") else
                            (m_l(51 downto 0)&(x"000000000000000000000")) when (val_sh_right="00000000001111") else
                            (m_l(55 downto 0)&(x"00000000000000000000")) when (val_sh_right="00000000010000") else
                            (m_l(59 downto 0)&(x"0000000000000000000")) when (val_sh_right="00000000010001") else
                            (m_l(63 downto 0)&(x"000000000000000000")) when (val_sh_right="00000000010010") else
                            (m_l(67 downto 0)&(x"00000000000000000")) when (val_sh_right="00000000010011") else
                            (m_l(71 downto 0)&(x"0000000000000000")) when (val_sh_right="00000000010100") else
                            (m_l(75 downto 0)&(x"000000000000000")) when (val_sh_right="00000000010101") else
                            (m_l(79 downto 0)&(x"00000000000000")) when (val_sh_right="00000000010110") else
                            (m_l(83 downto 0)&(x"0000000000000")) when (val_sh_right="00000000010111") else
                            (m_l(87 downto 0)&(x"000000000000")) when (val_sh_right="00000000011000") else
                            (m_l(91 downto 0)&(x"00000000000")) when (val_sh_right="00000000011001") else
                            (m_l(95 downto 0)&(x"0000000000")) when (val_sh_right="00000000011010") else
                            (m_l(99 downto 0)&(x"000000000")) when (val_sh_right="00000000011011") else
                            (m_l(103 downto 0)&(x"00000000")) when (val_sh_right="00000000011100") else
                            (m_l(107 downto 0)&(x"0000000")) when (val_sh_right="00000000011101") else
                            (m_l(111 downto 0)&(x"000000")) when (val_sh_right="00000000011110") else
                            (m_l(115 downto 0)&(x"00000")) when (val_sh_right="00000000011111") else
                            (m_l(119 downto 0)&(x"0000")) when (val_sh_right="00000000100000") else
                            (m_l(123 downto 0)&(x"000")) when (val_sh_right="00000000100001") else
                            (m_l(127 downto 0)&(x"00")) when (val_sh_right="00000000100010") else
                            (m_l(131 downto 0)&(x"0")) when (val_sh_right="00000000100011") else
                            m_l(135 downto 0); -- when (val_sh_right="00000000100100") else
                                                        
                            --(others => '0'); -- cuando Valsh_rigth = 0, 1, 2, o >P+2

            stb <= '0' when (eval_sticky= x"0000000000000000000000000000000000") else '1';     

 
                   
    end generate;

    m_l_ext(3 downto 0) <= "000"&stb;   
	
--  ==== detección de ceros en y armado de operandos


-- ==========
-- === Realización de las operación suma/resta en SVA

     e_AddSub: AS_SVA_CB_I
            generic map (TAddSub => 2, N => P+3)  
            port  map (  op => op,  s_a => s_g , a => m_g_ext,
                          s_b => s_l, b => m_l_ext,
                          co => cy_add, 
                          s_r => s_r_fix, r=> m_r_fix);

-- ========= 	
	



-- =============
-- ==== Para REDONDEO

-- === Previo al Redondeo    

    -- Explicación para P=7, y tengo como resultado -------,---. Esto es para mantisa previa al redondeo
    -- 1-En el caso que haya acarreo es porque fue una suma, entonces queda cy------.-- (descarto el menos significativo y sumará uno al exponente)
    
    -- 2-En el caso que no hay acarreo puede ser suma o resta
    -- 2.1- si el MSD del resultado es 0, es porque hubo resta y disminuyó la mantisa, entonces queda -------.-- (desplaza uno a izquierda y resto uno al exponente)
    -- 2.2. si MSD es diferente a 0, puede ser con suma o resta, entonces tomo los p+2 más significaticos del resultado -------.-- (mantiene valor del exponente)  
    
    m_r_pre_rd <=  ("0001"&m_r_fix(4*P+11 downto 8)) when (cy_add='1') else
                   (m_r_fix(4*P+7 downto 0)) when (m_r_fix(4*P+11 downto 4*P+8)="0000") else 
                    m_r_fix(4*P+11 downto 4);
    
-- === Redondeo    
    
    tmp_rd <=  m_r_fix(19 downto 0) when (cy_add='1') else
                  (m_r_fix(11 downto 0)&x"00") when (m_r_fix(4*P+11 downto 4*P+8)="0000") else 
                   (m_r_fix(15 downto 0)&x"0");
       -- señal de 5 dígitos BCD que posee lo que la unidad de redondeo requiere
    
    nequal <= '0'  when (tmp_rd(11 downto 0)=x"000")  else '1'; 
    -- usado por uniad de redondeo
    
    oper_zero_rd <= (others => '0');    
                        
    round_ties_Even: if TypeRound=4 generate
                           oper_rd <= '1'  when (((tmp_rd(15) ='1')  or  (tmp_rd(14 downto 13)="11"))   -- si segundo dígito es mayor a 5 
                                                 or((tmp_rd(15 downto 12)="0101") and (nequal='1'))) -- si segundo dígito es =5 y resto diferente a 0         
                                                 and (tmp_rd(16)='1')  -- si es impar el primer dígito 
                                           else '0';                       
                            
    end generate;
                    
    e_AddRound: adder_BCD_L6  generic map (TAdd => 2, NDigit => P)    
                                port map ( a => m_r_pre_rd(4*(P+2)-1 downto 8), b => oper_zero_rd, cin => oper_rd,
                                       cout => cy_add_rd, s => m_r_rd);
    -- si existe cy (cy_add_rd), se debe hacer corrimiento a izquierda y sumar uno al exponente del resultado                


-- ============	
-- ============	
	
	-- =============
	-- ===== Tratamiento del signo del resultado
	-- en el caso se intercambien los operandos y la operación original es resta, 
	-- entonces se debe invertir el signo que proviene del addSub SVA fixed 
	s_inv <= flg_sw and op and (sa xor sb); -- se agrea cuando and cuando la operacion efectiva es 0, y como  op=1, entonces sería cuando  sa!=sb
	sr <= s_r_fix xor s_inv;
	-- ===== Fin tratamiento del signo del resultado
	-- =============
    
   
        

	-- =============
	-- ===== Tratamiento del exponente del resultado
    -- Está todo alineado con el exponente del operando mayor. Se debe ajustar el valor shifteado a la izquierda
	-- que se corresponde con la min(diff, cantidad de ceros).
	val_sub_zeros <= (others => '0');
    val_sub_exp <= val_sub_zeros&val_sh_left;  
        
	                       
        
        --El ajuste es por corrimiento previo a redondeo y posterior a redondeo
        -- 1- Cuando cy_add es uno, significa que dio acarreo el valor previo al redondeo
        --     entonces no generá acarreo el redondeo. Se debe sumar uno al exponente
        
        -- 2- si no hay cy_add pero m_r_fix(4*P-11 downto 4*P-8)=0000, entonce fue en una resta que se debe desplazar a derecha
        --     en este caso no genera puede que genere acarreo el redondeo
        --     2.1- si genera acarreo el redondeo cy_add_rd entonces, se deja el exponente como está 
        --     2.2- si no genera acarreo el redondeo cy_add_rd=0, se resta uno al exponente
        
        -- 3- Cuando estoy en situación normal previa a redondeo y genera acarreo el redondeo
        -- es decir cy_add_rd=1, entonces suma uno al exponente          
     
     -- ===== FIN AJUSTE POR REDONDEO   
	
    
    q_pre <= q_g - val_sub_exp; -- q_g posee el bias, le resta el valor shifeado sin bias. Entonces q_pre ya posee el bias
    
    
    qr <= (q_pre + 1) when (cy_add='1') else 
          (q_pre - 1) when ( (m_r_fix(4*P+11 downto 4*P+8)="0000") and (cy_add_rd='0')) else
          (q_pre + 1) when ( (m_r_fix(4*P+11 downto 4*P+8)/="0000") and (cy_add_rd='1')) else
          q_pre;  

                      
    -- Fin tratamiento del exponente del resultado
    -- ==================

    
   mr <= ("0001"&m_r_rd(4*P-1 downto 4))when (cy_add_rd='1') else m_r_rd;
   	
	
	
end Behavioral;

