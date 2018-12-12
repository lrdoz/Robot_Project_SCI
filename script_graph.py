import csv
import sys
from operator import itemgetter
import matplotlib.pyplot as plt

def plotage(x_axe, y_axe, labels, nb_values, x_lab, y_lab):
    print(x_axe)
    for i in range(nb_values):
        plt.bar(x_axe, y_axe[i], label=labels[i])
    plt.xlabel(x_lab)
    plt.ylabel(y_lab)
    plt.legend(loc='upper left')
    plt.show()

def lissage(csv_val, repet, nb_values):
    x_axe = []
    y_axe = [[] for x in range(0,nb_values)]
    i = 0
    while (i < len(csv_val)):
        end_i = i
        key_val = csv_val[i][0]
    # for i in range(0,len(csv_val), repet):
        x_axe.append(key_val)
        while ((end_i < len(csv_val)) and (csv_val[end_i][0] == key_val)):
            end_i+=1
        # means = []
        for j in range(1, nb_values+1):
            #
            l = [row[j] for row in csv_val[i:end_i]]
            new_mean = sum(l)/len(l)
            y_axe[j-1].append(new_mean)
        i = end_i
        # y_axe.append(means)
    # print(x_axe, y_axe)
    return x_axe, y_axe

def sort_by_val(csv_val):
    return sorted(csv_val, key=itemgetter(0))

def main(csv_name,repet, index, min_values, max_values, x_lab, y_lab):
    with open(csv_name) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        csv_val = []
        for row in csv_reader:
            if line_count < 6:
                line_count += 1
            elif line_count == 6:
                labels = row[min_values:max_values+1]
                print(labels)
                line_count += 1
            else :
                line_count += 1
                try:
                    new_val = [row[int(index)]]+list(map(float,row[min_values:max_values+1]))
                except:
                    new_val = [row[index]]+list(map(float,row[min_values:max_values+1]))

                csv_val.append(new_val)
            # if line_count == 0:
            #     print(f'Column names are {", ".join(row)}')
            #     line_count += 1
            # else:
            #     print(row)
            #     line_count += 1

        # print(csv_val)
        csv_val = sort_by_val(csv_val)
        # print(csv_val)
        x_axe,y_axe = lissage(csv_val, repet, max_values-min_values+1)
        plotage(x_axe, y_axe, labels, max_values-min_values+1, x_lab, y_lab)
        print(f'Processed {line_count} lines.')

if __name__ == "__main__":
    # execute only if run as a script

    # argument 1 nom du ficher csv
    # argument 2 nombre de répétition
    # argument 3 la valeur qui varie
    # argument 4 nombre de valeurs qu'on veut regarder
    # reste nom des axes
    main(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6], sys.argv[7])
