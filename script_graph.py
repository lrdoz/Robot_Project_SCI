import csv
import sys
from operator import itemgetter
import matplotlib.pyplot as plt

def plotage(x_axe, y_axe, labels, nb_values, x_lab, y_lab):
    for i in range(nb_values):
        plt.plot(x_axe, y_axe[i], label=labels[i])
    plt.xlabel(x_lab)
    plt.ylabel(y_lab)
    plt.legend(loc='upper right')
    plt.show()

def lissage(csv_val, repet, nb_values):
    x_axe = []
    y_axe = [[] for x in range(0,nb_values)]
    for i in range(0,len(csv_val), repet):
        x_axe.append(csv_val[i][0])
        # means = []
        for j in range(1, nb_values+1):
            #
            l = [row[j] for row in csv_val[i:i+repet]]
            new_mean = sum(l)/len(l)
            y_axe[j-1].append(new_mean)
        # y_axe.append(means)
    # print(x_axe, y_axe)
    return x_axe, y_axe

def sort_by_val(csv_val):
    return sorted(csv_val, key=itemgetter(0))

def main(csv_name,repet, index, nb_values, x_lab, y_lab):
    with open(csv_name) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        csv_val = []
        for row in csv_reader:
            if line_count < 6:
                line_count += 1
            elif line_count == 6:
                labels = row[-nb_values:]
                print(labels)
                line_count += 1
            else :
                line_count += 1
                new_val = [row[index]]+list(map(float,row[-nb_values:]))
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
        x_axe,y_axe = lissage(csv_val, repet, nb_values)
        plotage(x_axe, y_axe, labels, nb_values, x_lab, y_lab)
        print(f'Processed {line_count} lines.')

if __name__ == "__main__":
    # execute only if run as a script

    # argument 1 nom du ficher csv
    # argument 2 nombre de répétition
    # argument 3 la valeur qui varie
    # argument 4 nombre de valeurs qu'on veut regarder
    main(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5], sys.argv[6])
