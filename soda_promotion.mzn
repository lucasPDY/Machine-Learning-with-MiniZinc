% 9 Different Types of Soda
enum SODA = {'DC Kola', 'AB Root Beer', 'Mr. Popper', 'Popsi Kola', 'Alpine Stream', '11 Down', 'Bright', 'Koala Kola', 'Crisp Clear'};

% Sodas can either be CLEAR or DARK
enum FAMILY = {'CLEAR', 'DARK'};
array[FAMILY] of int: maxFamily = [2,2];
% Normal Prices of each of the different Sodas
array[SODA] of float: normalPrice = [1.9325, 3.8425, 2.985, 1.75, 2.2275, 1.56, 1.29, 2.565, 1.47];

% The Soda Family of the corresponding Soda
array[SODA] of FAMILY: soda_family = ['DARK', 'DARK', 'DARK', 'DARK', 'CLEAR', 'CLEAR', 'CLEAR', 'DARK', 'CLEAR'];

% Predicted Sales using normal prices for each Soda
array[SODA] of float: normalQuantity = [634.1590562690039, 414.0552315233731, 24.098438584058385,  210.2953825858499, 104.8372729804446, 152.1772936405573,  2663.8434281990044, 1029.616590103608, 116.11557168695253,];

% number of rows in the dataset
int: max_investment = 750;
int: n =  36;
set of int: ROWS = 1..n;

% Predicted Sales for each promotional price
array[ROWS] of float: promotionalQuantity =  [241.07707900109335, 157.7694074583328, 270.4797866044205, 116.11557168695253, 443.45793912670024, 414.0552315233731, 485.11177489808006, 524.3153850358499, 107.40611012681939, 24.098438584058385, 158.86084843264143, 112.30656139404027, 114.75678702765072, 1059.019297706935, 1110.4740360127576, 1034.5170413708288, 1029.616590103608, 255.0867702522023, 152.1772936405573, 174.22932434305267, 198.73158067915847, 2671.194105099836, 2663.8434281990044, 2680.995007634279, 286.2523772277782, 232.34741328834525, 210.2953825858499, 247.04876709000882, 634.1590562690039, 675.8128920403847, 651.3106357042784, 641.5097331698357, 104.8372729804446, 193.04539579042603, 180.79426762237335, 330.2580312726195];

% Different Promotional Prices for different Sodas
array[ROWS] of float: promotionalPrice = [1.3425, 1.4275, 1.3125, 1.47, 3.8125, 3.8425, 3.77, 3.73, 2.9, 2.985, 2.8475, 2.895, 2.8925, 2.535, 2.4825, 2.56, 2.565, 1.455, 1.56, 1.5375, 1.5125, 1.2825, 1.29, 1.2725, 1.6725, 1.7275, 1.75, 1.7125, 1.9325, 1.89, 1.915, 1.925, 2.2275, 2.1375, 2.15, 1.9975];

% Different Sodas
array[ROWS] of SODA: product_type = ['Crisp Clear', 'Crisp Clear', 'Crisp Clear', 'Crisp Clear', 'AB Root Beer', 'AB Root Beer', 'AB Root Beer', 'AB Root Beer', 'Mr. Popper', 'Mr. Popper', 'Mr. Popper', 'Mr. Popper', 'Mr. Popper', 'Koala Kola', 'Koala Kola', 'Koala Kola', 'Koala Kola', '11 Down', '11 Down', '11 Down', '11 Down', 'Bright', 'Bright', 'Bright', 'Popsi Kola', 'Popsi Kola', 'Popsi Kola', 'Popsi Kola', 'DC Kola', 'DC Kola', 'DC Kola', 'DC Kola', 'Alpine Stream', 'Alpine Stream', 'Alpine Stream', 'Alpine Stream'];

% Decision Array that shows which product and prices are chosen among the different sodas and prices
array[ROWS] of var 0..1: selected;

var float: investment;
var float: sales;
var float: revenue;

% Investment must be non-negative and <= maximum investment
constraint investment >= 0 /\ investment <= max_investment;
% Sales and Revenue must be non-negative
constraint sales >= 0;
constraint revenue >= 0;

% for each product, only one promotional price is selected
constraint forall(i in SODA)((sum(j in 1..n where product_type[j] = i)(selected[j])) = 1);

% Sales is the total quantity of product sold
constraint sales = sum(i in 1..n) (selected[i] * promotionalQuantity[i]);
constraint revenue = sum(i in 1..n) (selected[i] * promotionalQuantity[i] * promotionalPrice[i]);
% assume quantity of products sold using promotional prices > quantity of products sold using normal prices
constraint investment = sum(i in 1..n) ((promotionalQuantity[i] - normalQuantity[product_type[i]]) * normalPrice[product_type[i]] * selected[i]);
% for each soda family, promotional prices used is not greater than the limit set
constraint forall(f in FAMILY) ((sum(i in 1..n where soda_family[product_type[i]] = f /\ promotionalPrice[i] != normalPrice[product_type[i]]) (selected[i])) <= maxFamily[f]);


array[1..9] of SODA: x = ['Crisp Clear','AB Root Beer', 'Mr. Popper', 'Koala Kola', '11 Down', 'Bright', 'Popsi Kola', 'DC Kola', 'Alpine Stream'];

% constraint forall(i in 1..9) (sodas[i] = )
% Maximize Sales 
solve maximize sales;
output  ["selected = {"] ++ [if fix(selected[i]) = 1 then show(product_type[i])  ++  ", " else "" endif | i in 1..n ] ++ ["};\n"] ++ 
["promotionalPrices = {"] ++ [if fix(selected[i]) = 1 then show(promotionalPrice[i]) ++ ", "  else " " endif | i in 1..n ] ++ ["};\n"] ++ ["investment = \(investment);\nsales = \(sales);\nrevenue = \(revenue);"];
