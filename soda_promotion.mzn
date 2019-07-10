% Use this editor as a MiniZinc scratch book
enum PROD = {'DC Kola', 'AB Root Beer', 'Mr. Popper', 'Popsi Kola', 'Alpine Stream', '11 Down', 'Bright', 'Koala Kola', 'Crisp Clear'};
enum SODA = {'CLEAR', 'DARK'};
array[PROD] of float: normalPrice = [1.9325, 3.8425, 2.985, 1.75, 2.2275, 1.56, 1.29, 2.565, 1.47];
array[PROD] of SODA: soda_family = ['DARK', 'DARK', 'DARK', 'DARK', 'CLEAR', 'CLEAR', 'CLEAR', 'DARK', 'CLEAR'];

int: n =  36;
set of int: ROWS = 1..n;
array[ROWS] of float: quantity =  [241.07707900109335, 157.7694074583328, 270.4797866044205, 116.11557168695253, 443.45793912670024, 414.0552315233731, 485.11177489808006, 524.3153850358499, 107.40611012681939, 24.098438584058385, 158.86084843264143, 112.30656139404027, 114.75678702765072, 1059.019297706935, 1110.4740360127576, 1034.5170413708288, 1029.616590103608, 255.0867702522023, 152.1772936405573, 174.22932434305267, 198.73158067915847, 2671.194105099836, 2663.8434281990044, 2680.995007634279, 286.2523772277782, 232.34741328834525, 210.2953825858499, 247.04876709000882, 634.1590562690039, 675.8128920403847, 651.3106357042784, 641.5097331698357, 104.8372729804446, 193.04539579042603, 180.79426762237335, 330.2580312726195];
array[ROWS] of float: price = [1.3425, 1.4275, 1.3125, 1.47, 3.8125, 3.8425, 3.77, 3.73, 2.9, 2.985, 2.8475, 2.895, 2.8925, 2.535, 2.4825, 2.56, 2.565, 1.455, 1.56, 1.5375, 1.5125, 1.2825, 1.29, 1.2725, 1.6725, 1.7275, 1.75, 1.7125, 1.9325, 1.89, 1.915, 1.925, 2.2275, 2.1375, 2.15, 1.9975];
array[ROWS] of float: normalQuantity = [116.11557168695253, 116.11557168695253, 116.11557168695253, 116.11557168695253, 414.0552315233731, 414.0552315233731, 414.0552315233731, 414.0552315233731, 24.098438584058385, 24.098438584058385, 24.098438584058385, 24.098438584058385, 24.098438584058385, 1029.616590103608, 1029.616590103608, 1029.616590103608, 1029.616590103608, 152.1772936405573, 152.1772936405573, 152.1772936405573, 152.1772936405573, 2663.8434281990044, 2663.8434281990044, 2663.8434281990044, 210.2953825858499, 210.2953825858499, 210.2953825858499, 210.2953825858499, 634.1590562690039, 634.1590562690039, 634.1590562690039, 634.1590562690039, 104.8372729804446, 104.8372729804446, 104.8372729804446, 104.8372729804446];
array[ROWS] of PROD: product_type = ['Crisp Clear', 'Crisp Clear', 'Crisp Clear', 'Crisp Clear', 'AB Root Beer', 'AB Root Beer', 'AB Root Beer', 'AB Root Beer', 'Mr. Popper', 'Mr. Popper', 'Mr. Popper', 'Mr. Popper', 'Mr. Popper', 'Koala Kola', 'Koala Kola', 'Koala Kola', 'Koala Kola', '11 Down', '11 Down', '11 Down', '11 Down', 'Bright', 'Bright', 'Bright', 'Popsi Kola', 'Popsi Kola', 'Popsi Kola', 'Popsi Kola', 'DC Kola', 'DC Kola', 'DC Kola', 'DC Kola', 'Alpine Stream', 'Alpine Stream', 'Alpine Stream', 'Alpine Stream'];
array[ROWS] of var 0..1: selected;
int: max_investment = 750;
var float: investment;
var float: sales;
var float: revenue;
constraint investment >= 0 /\ investment <= max_investment;
constraint sales >= 0;
constraint revenue >= 0;

% for each product, only one price is selected
constraint forall(i in PROD)((sum(j in 1..n where product_type[j] = i)(selected[j])) = 1);

constraint sales = sum(i in 1..n) (selected[i] * quantity[i]);
constraint revenue = sum(i in 1..n) (selected[i] * quantity[i] * price[i]);
constraint investment = sum(i in 1..n) ((quantity[i] - normalQuantity[i]) * normalPrice[product_type[i]] * selected[i]);

constraint forall(f in SODA) ((sum(i in 1..n where soda_family[product_type[i]] = f /\ price[i] != normalPrice[product_type[i]]) (selected[i])) <= 2);
solve maximize sales;
output  ["selected = {"] ++ [if fix(selected[i]) = 1 then show(product_type[i])  else "" endif | i in 1..n ] ++ ["};\n"] ++ 
["prices = {"] ++ [if fix(selected[i]) = 1 then show(price[i])  else " " endif | i in 1..n ] ++ ["};\n"] ++ ["investment = \(investment);\nsales = \(sales);\nrevenue = \(revenue);"];
% output ["raid = {"] ++ [if fix(raid[i]) != dummy then show(raid[i]) ++ if i < u /\ fix(raid[i+1]) != dummy then ", " else "" endif else "" endif | i in 1..u ] ++ ["};\n"] ++ ["obj = \(obj);\n"];